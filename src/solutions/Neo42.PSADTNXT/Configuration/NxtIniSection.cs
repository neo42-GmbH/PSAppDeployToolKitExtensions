using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Dynamic;
using System.Linq;
using System.Linq.Expressions;
using System.Management.Automation;

namespace PSADTNXT.Configuration
{
#pragma warning disable CA1710
	public sealed class NxtIniSection : IDynamicMetaObjectProvider, ICloneable, IDictionary<string, string>
#pragma warning restore CA1710
	{
		private record SettingContainer
		{
			public string Value = "";
			public string Comment = "";
		}

		private readonly OrderedDictionary _settings;

		public bool IsReadOnly => _settings.IsReadOnly;

		public NxtIniSection()
		{
			_settings = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
		}

		private NxtIniSection(OrderedDictionary dictionary)
		{
			_settings = dictionary;
		}

		internal NxtIniSection AsReadOnly()
		{
			return new NxtIniSection(_settings.AsReadOnly());
		}

		/// <summary>
		/// Parses the comment of a setting to extract a metadata dictionary.
		///
		/// The block must be formatted as follows:
		/// Metadata:
		/// Key1 = Value
		/// Key2 = Value
		///
		/// Lines that do not contain an '=' character are ignored, as well as lines after an empty line following the Metadata: header.
		/// </summary>
		/// <param name="key">The setting name whose comment should be parsed for metadata.</param>
		/// <returns>A dictionary containing the metadata key-value pairs.</returns>
		public Dictionary<string, string> GetMetadata(string key)
		{
			var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
			var commentLines = GetComment(key).Split([Environment.NewLine], StringSplitOptions.None);
			var startIndex = Array.FindIndex(commentLines, line => line.Trim().Equals("Metadata:", StringComparison.OrdinalIgnoreCase));
			if (startIndex == -1)
			{
				return result; // No Metadata block found
			}

			var endIndex = Array.FindIndex(commentLines, startIndex + 1, string.IsNullOrWhiteSpace);
			var metadataLines = endIndex == -1 ? commentLines.Skip(startIndex + 1) : commentLines.Skip(startIndex + 1).Take(endIndex - startIndex - 1);

			foreach (var line in metadataLines)
			{
				if (line.Contains('='))
				{
					var parts = line.Split(['='], 2);
					result[parts[0].Trim()] = parts[1].Trim();
				}
			}

			return result;
		}

		public void SetComment(string name, string comment)
		{
			if (IsReadOnly)
			{
				throw new InvalidOperationException("The section is read-only.");
			}
			if (_settings[name] is SettingContainer setting)
			{
				setting.Comment = comment;
			}
			else
			{
				throw new KeyNotFoundException($"The setting '{name}' does not exist in this section.");
			}
		}

		public string GetComment(string name)
		{
			return _settings[name] is SettingContainer setting
				? setting.Comment
				: throw new KeyNotFoundException($"The setting '{name}' does not exist in this section.");
		}

		#region IDynamicMetaObjectProvider Members
		[Hidden]
		public DynamicMetaObject GetMetaObject(Expression parameter)
		{
			return new IniSectionMetaObject(parameter, this);
		}

		private class IniSectionMetaObject : DynamicMetaObject
		{
			public IniSectionMetaObject(Expression expression, NxtIniSection section)
				: base(expression, BindingRestrictions.Empty, section) { }

			public override IEnumerable<string> GetDynamicMemberNames()
			{
				return ((NxtIniSection)Value!).Keys.Concat(base.GetDynamicMemberNames());
			}

			public override DynamicMetaObject BindGetMember(GetMemberBinder binder)
			{
				var section = (NxtIniSection)Value!;

				if (section._settings.Contains(binder.Name))
				{
					var expression = Expression.Property(
						Expression.Convert(Expression, typeof(NxtIniSection)),
						typeof(NxtIniSection).GetProperty("Item", [typeof(string)])!,
						Expression.Constant(binder.Name)
					);

					var restrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniSection))
						.Merge(BindingRestrictions.GetExpressionRestriction(
							Expression.Call(
								Expression.Convert(Expression, typeof(NxtIniSection)),
								typeof(NxtIniSection).GetMethod("ContainsKey")!,
								Expression.Constant(binder.Name)
							)
						));

					return new DynamicMetaObject(expression, restrictions);
				}

				var baseRestrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniSection))
					.Merge(BindingRestrictions.GetExpressionRestriction(
						Expression.Not(
							Expression.Call(
								Expression.Convert(Expression, typeof(NxtIniSection)),
								typeof(NxtIniSection).GetMethod("ContainsKey")!,
								Expression.Constant(binder.Name)
							)
						)
					));

				var baseResult = base.BindGetMember(binder);
				return new DynamicMetaObject(baseResult.Expression, baseRestrictions.Merge(baseResult.Restrictions));
			}

			public override DynamicMetaObject BindSetMember(SetMemberBinder binder, DynamicMetaObject value)
			{
				var convertExpression = Expression.Call(
					typeof(LanguagePrimitives).GetMethod("ConvertTo", [typeof(object)])!.MakeGenericMethod(typeof(string)),
					Expression.Convert(value.Expression, typeof(object))
				);

				var expression = Expression.Assign(
					Expression.Property(
						Expression.Convert(Expression, typeof(NxtIniSection)),
						typeof(NxtIniSection).GetProperty("Item", [typeof(string)])!,
						Expression.Constant(binder.Name)
					),
					convertExpression
				);
				var restrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniSection));
				return new DynamicMetaObject(expression, restrictions);
			}
		}
		#endregion IDynamicMetaObjectProvider Members

		#region IOrderedDictionary<string, NxtIniSetting> Members
		public string this[string settingName]
		{
			get => _settings[settingName] is SettingContainer setting ? setting.Value : string.Empty;
			set
			{
				if (IsReadOnly)
				{
					throw new InvalidOperationException("The section is read-only.");
				}
				else if (_settings[settingName] is SettingContainer setting)
				{
					setting.Value = value;
				}
				else
				{
					_settings[settingName] = new SettingContainer { Value = value, Comment = string.Empty };
				}
			}
		}

		public string this[int index]
		{
			get => _settings[index] is SettingContainer setting ? setting.Value : string.Empty;
			set
			{
				if (IsReadOnly)
				{
					throw new InvalidOperationException("The section is read-only.");
				}
				else if (_settings[index] is SettingContainer setting)
				{
					setting.Value = value;
				}
				else
				{
					_settings[index] = new SettingContainer { Value = value, Comment = string.Empty };
				}
			}
		}

		public bool ContainsKey(string key)
		{
			return _settings.Contains(key);
		}

		public bool Contains(KeyValuePair<string, string> item)
		{
			return _settings[item.Key] is SettingContainer setting && setting.Value == item.Value;
		}

		public void Add(string key, string value, string comment)
		{
			if (IsReadOnly)
			{
				throw new InvalidOperationException("The section is read-only.");
			}
			_settings.Add(key, new SettingContainer { Value = value, Comment = comment });
		}

		public void Add(string key, string value)
		{
			Add(key, value, string.Empty);
		}

		public void Add(KeyValuePair<string, string> item)
		{
			Add(item.Key, item.Value, string.Empty);
		}

		public void Insert(int index, string key, string value, string comment = "")
		{
			if (IsReadOnly)
			{
				throw new InvalidOperationException("The section is read-only.");
			}
			_settings.Insert(index, key, new SettingContainer { Value = value, Comment = comment });
		}

		public void Insert(int index, KeyValuePair<string, string> item)
		{
			Insert(index, item.Key, item.Value, string.Empty);
		}

		public bool Remove(string key)
		{
			if (IsReadOnly)
			{
				throw new InvalidOperationException("The section is read-only.");
			}
			if (_settings.Contains(key))
			{
				_settings.Remove(key);
				return true;
			}
			else
			{
				return false;
			}
		}

		public bool Remove(KeyValuePair<string, string> item)
		{
			return Remove(item.Key);
		}

		public bool TryGetValue(string key, out string value)
		{
			if (_settings[key] is SettingContainer container)
			{
				value = container.Value;
				return true;
			}
			else
			{
				value = string.Empty;
				return false;
			}
		}

		public void Clear()
		{
			_settings.Clear();
		}

		public void CopyTo(KeyValuePair<string, string>[] array, int arrayIndex)
		{
			foreach (string settingName in _settings.Keys)
			{
				array[arrayIndex++] = new KeyValuePair<string, string>(settingName, ((SettingContainer)_settings[settingName]!).Value);
			}
		}

		public IEnumerator<KeyValuePair<string, string>> GetEnumerator()
		{
			foreach (string settingName in _settings.Keys)
			{
				yield return new KeyValuePair<string, string>(settingName, ((SettingContainer)_settings[settingName]!).Value);
			}
		}

		public object Clone()
		{
			var clone = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
			foreach (KeyValuePair<string, SettingContainer> kvp in _settings)
			{
				clone[kvp.Key] = kvp.Value;
			}
			return clone;
		}

		IEnumerator IEnumerable.GetEnumerator()
		{
			return GetEnumerator();
		}

		public ICollection<string> Keys => [.. _settings.Keys.Cast<string>()];

		public ICollection<string> Values => [.. _settings.Values.Cast<string>()];

		public int Count => _settings.Count;
		#endregion IOrderedDictionary<string, NxtIniSetting> Members
	}
}
