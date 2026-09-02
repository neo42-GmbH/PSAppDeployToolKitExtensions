using System;
using System.IO;
using System.Collections.Generic;
using System.Collections;
using System.Linq;
using System.Text;
using System.Dynamic;
using System.Globalization;
using System.Linq.Expressions;
using System.Management.Automation;
using System.Collections.Specialized;

namespace PSADTNXT.Configuration
{
#pragma warning disable CA1710
	public sealed class NxtIniDocument : IDynamicMetaObjectProvider, ICloneable, IDictionary<string, NxtIniSection>
#pragma warning restore CA1710
	{
		private record SectionContainer
		{
			public NxtIniSection Section = null!;

			private string _comment = "";
			public string Comment
			{
				get => _comment;
				set
				{
					if (Section.IsReadOnly)
					{
						throw new InvalidOperationException("The section is read-only.");
					}
					_comment = value;
				}
			}
		}

		private readonly OrderedDictionary _sections;

		public bool IsReadOnly => _sections.IsReadOnly;

		public NxtIniDocument()
		{
			_sections = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
		}

		private NxtIniDocument(OrderedDictionary sections)
		{
			_sections = sections;
		}

		public static implicit operator Hashtable(NxtIniDocument iniDocument)
		{
			return iniDocument.ToHashtable();
		}

		public Hashtable ToHashtable()
		{
			var hashTable = new Hashtable(StringComparer.OrdinalIgnoreCase);
			foreach (var sectionKey in _sections.Keys)
			{
				var sectionHashTable = new Hashtable(StringComparer.OrdinalIgnoreCase);
				var section = (SectionContainer)_sections[sectionKey]!;
				foreach (var settingKey in section.Section.Keys)
				{
					sectionHashTable.Add(settingKey, section.Section[settingKey]);
				}
				hashTable.Add(sectionKey, sectionHashTable);
			}
			return hashTable;
		}

		public NxtIniDocument AsReadOnly()
		{
			return new NxtIniDocument(_sections.AsReadOnly());
		}

		public void SetComment(string name, string comment)
		{
			if (_sections[name] is SectionContainer section)
			{
				section.Comment = comment;
			}
			else
			{
				throw new KeyNotFoundException($"The setting '{name}' does not exist in this section.");
			}
		}

		public string GetComment(string name)
		{
			return _sections[name] is SectionContainer section
				? section.Comment
				: throw new KeyNotFoundException($"The setting '{name}' does not exist in this section.");
		}

		public void Parse(string content)
		{
			_sections.Clear();
			var lines = content.Split(["\r\n", "\n"], StringSplitOptions.None);
			var commentBuffer = new StringBuilder();
			var counter = 0;

			var globalSectionCreated = false;
			SectionContainer currentSection;

			if (_sections[""] is SectionContainer globalSection)
			{
				currentSection = globalSection;
			}
			else
			{
				currentSection = new SectionContainer
				{
					Section = [],
					Comment = string.Empty
				};
				_sections.Insert(0, "", currentSection);
				globalSectionCreated = true;
			}

			foreach (var line in lines)
			{
				counter++;
				var text = line.Trim();
				if (text.StartsWith(";") || text.StartsWith("#"))
				{
					if (commentBuffer.Length > 0)
					{
						_ = commentBuffer.AppendLine();
					}

					_ = commentBuffer.Append($"{text.Substring(1)}");
					continue;
				}

				if (string.IsNullOrWhiteSpace(text))
				{
					continue;
				}

				if (text.StartsWith("[") && text.EndsWith("]"))
				{
					var sectionName = text.Substring(1, text.Length - 2);
					if (!_sections.Contains(sectionName))
					{
						currentSection = new SectionContainer
						{
							Section = [],
							Comment = commentBuffer.ToString()
						};
						_sections.Add(sectionName, currentSection);
					}
					else
					{
						throw new FormatException($"Duplicate section [{sectionName}] found in line {counter}: {line}");
					}
					_ = commentBuffer.Clear();
				}
				else if (text.Contains('='))
				{
					var parts = text.Split('=');
					var key = parts.First().Trim();
					var value = string.Join("=", parts.Skip(1)).Trim();

					currentSection.Section.Add(key, value, commentBuffer.ToString());
					_ = commentBuffer.Clear();
				}
				else
				{
					throw new FormatException($"Invalid format in line {counter}: {line}");
				}
			}

			if (globalSectionCreated && _sections[""] is SectionContainer currentGlobalSection && currentGlobalSection.Section.Count == 0)
			{
				_sections.Remove("");
			}
		}

		public static NxtIniDocument CreateFrom(string filePath)
		{
			var iniDocument = new NxtIniDocument();
			iniDocument.LoadFrom(filePath);
			return iniDocument;
		}

		public static NxtIniDocument CreateFrom(IDictionary dict, bool convertBoolToInt = false)
		{
			var iniDocument = new NxtIniDocument();
			iniDocument.LoadFrom(dict, convertBoolToInt);
			return iniDocument;
		}

		public void LoadFrom(string filePath)
		{
			if (!File.Exists(filePath))
			{
				throw new FileNotFoundException("File not found", filePath);
			}
			Parse(File.ReadAllText(filePath));
		}

		public void LoadFrom(IDictionary dict, bool convertBoolToInt = false)
		{
			foreach (DictionaryEntry entry in dict)
			{
				var currentSectionName = entry.Key.ToString();
				if (_sections.Contains(currentSectionName!))
				{
					throw new ArgumentException($"Duplicate section '{currentSectionName}' found in the provided dictionary.");
				}

				var currentSection = new SectionContainer
				{
					Section = [],
					Comment = string.Empty
				};

				_sections.Add(currentSectionName!, currentSection);

				foreach (DictionaryEntry setting in (IDictionary)entry.Value!)
				{
					var settingValue = setting.Value;
					if (convertBoolToInt && settingValue is bool boolValue)
					{
						settingValue = boolValue ? 1 : 0;
					}
					currentSection.Section.Add(setting.Key.ToString()!, settingValue!.ToString()!);
				}
			}
		}

		public void Merge(NxtIniDocument other, bool overwrite = false)
		{
			foreach (var section in other)
			{
				if (_sections[section.Key] is SectionContainer sectionContainer)
				{
					foreach (var setting in section.Value)
					{
						if (sectionContainer.Section.ContainsKey(setting.Key) && overwrite)
						{
							sectionContainer.Section[setting.Key] = setting.Value;
						}
						else if (!sectionContainer.Section.ContainsKey(setting.Key))
						{
							sectionContainer.Section.Add(setting.Key, setting.Value);
						}
					}
				}
				else
				{
					_sections.Add(section.Key, new SectionContainer
					{
						Section = section.Value,
						Comment = string.Empty
					});
				}
			}
		}

#pragma warning disable CA1021
		public bool Validate(out string[] errors)
#pragma warning restore CA1021
		{
			var errorList = new List<string>();
			foreach (string sectionName in _sections.Keys)
			{
				var section = (SectionContainer)_sections[sectionName]!;
				foreach (var setting in section.Section)
				{
					if (section.Section.GetMetadata(setting.Key) is not Dictionary<string, string> metaData)
					{
						continue;
					}

					if (metaData.TryGetValue("Values", out var values)
						&& values is string validValues
						&& !string.IsNullOrEmpty(validValues)
						&& !string.IsNullOrWhiteSpace(setting.Value)
						&& !validValues.Split(',').Select(static v => v.Trim()).Contains(setting.Value, StringComparer.OrdinalIgnoreCase))
					{
						errorList.Add($"The value [{setting.Value}] is not valid for setting [{setting.Key}] of section [{sectionName}]. Valid values are: {validValues}.");
					}

					if (metaData.TryGetValue("Type", out var typeName) && !string.IsNullOrWhiteSpace(typeName))
					{
						if (Enum.TryParse(typeName.Trim(), true, out IniTypeMetadata type))
						{
							if (!string.IsNullOrWhiteSpace(setting.Value))
							{
								switch (type)
								{
									case IniTypeMetadata.Int:
										if (!int.TryParse(setting.Value, out _))
										{
											errorList.Add($"Value [{setting.Value}] cannot be parsed as int in setting [{setting.Key}] of section [{sectionName}].");
										}
										break;
									case IniTypeMetadata.Date:
										if (!DateTime.TryParse(setting.Value, null, DateTimeStyles.None, out _))
										{
											errorList.Add($"Value [{setting.Value}] cannot be parsed as DateTime in setting [{setting.Key}] of section [{sectionName}].");
										}
										break;
									case IniTypeMetadata.String:
									default:
										break;
								}
							}
						}
						else
						{
#pragma warning disable CA2263
							errorList.Add($"Type metadata [{metaData["Type"]}] in setting [{setting.Key}] of section [{sectionName}] is not valid. Valid types are: {string.Join(", ", Enum.GetNames(typeof(IniTypeMetadata)))}.");
#pragma warning restore CA2263
						}
					}
				}
			}
			errors = [.. errorList];
			return errorList.Count == 0;
		}

		public string Export()
		{
			var sb = new StringBuilder();
			foreach (string sectionName in _sections.Keys)
			{
				var section = (SectionContainer)_sections[sectionName]!;
				if (!string.IsNullOrWhiteSpace(GetComment(sectionName)))
				{
					var comments = GetComment(sectionName).Split(["\r\n", "\n", "\r"], StringSplitOptions.None).Select(static c => $";{c}").ToArray();
					_ = sb.AppendLine(string.Join(Environment.NewLine, comments));
					_ = sb.AppendLine();
				}
				if (!string.IsNullOrEmpty(sectionName))
				{
					_ = sb.AppendLine($"[{sectionName}]");
					_ = sb.AppendLine();
				}
				foreach (var setting in section.Section)
				{
					if (!string.IsNullOrWhiteSpace(section.Section.GetComment(setting.Key)))
					{
						var comments = section.Section.GetComment(setting.Key).Split(["\r\n", "\n", "\r"], StringSplitOptions.None).Select(static c => $";{c}").ToArray();
						_ = sb.AppendLine(string.Join(Environment.NewLine, comments));
						_ = sb.AppendLine();
					}
					_ = sb.AppendLine($"{setting.Key}={setting.Value}".TrimEnd());
					_ = sb.AppendLine();
				}
				_ = sb.AppendLine();
			}
			return sb.ToString().TrimEnd();
		}

		public string Export(string filePath)
		{
			var content = Export();
			File.WriteAllText(filePath, content);
			return content;
		}

		#region IDynamicMetaObjectProvider Members
		[Hidden]
		public DynamicMetaObject GetMetaObject(Expression parameter)
		{
			return new IniDocumentMetaObject(parameter, this);
		}

		private class IniDocumentMetaObject : DynamicMetaObject
		{
			public IniDocumentMetaObject(Expression expression, NxtIniDocument iniDocument)
				: base(expression, BindingRestrictions.Empty, iniDocument) { }

			public override IEnumerable<string> GetDynamicMemberNames()
			{
				return ((NxtIniDocument?)Value)?.Keys.Concat(base.GetDynamicMemberNames()) ?? [];
			}

			public override DynamicMetaObject BindGetMember(GetMemberBinder binder)
			{
				var document = (NxtIniDocument)Value!;

				if (document.ContainsKey(binder.Name))
				{
					var expression = Expression.Property(
						Expression.Convert(Expression, typeof(NxtIniDocument)),
						typeof(NxtIniDocument).GetProperty("Item", [typeof(string)])!,
						Expression.Constant(binder.Name)
					);

					var restrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniDocument))
						.Merge(BindingRestrictions.GetExpressionRestriction(
							Expression.Call(
								Expression.Convert(Expression, typeof(NxtIniDocument)),
								typeof(NxtIniDocument).GetMethod("ContainsKey")!,
								Expression.Constant(binder.Name)
							)
						));

					return new DynamicMetaObject(expression, restrictions);
				}

				var baseRestrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniDocument))
					.Merge(BindingRestrictions.GetExpressionRestriction(
						Expression.Not(
							Expression.Call(
								Expression.Convert(Expression, typeof(NxtIniDocument)),
								typeof(NxtIniDocument).GetMethod("ContainsKey")!,
								Expression.Constant(binder.Name)
							)
						)
					));

				var baseResult = base.BindGetMember(binder);
				return new DynamicMetaObject(baseResult.Expression, baseRestrictions.Merge(baseResult.Restrictions));
			}

			public override DynamicMetaObject BindSetMember(SetMemberBinder binder, DynamicMetaObject value)
			{
				var expression = Expression.Assign(
					Expression.Property(
						Expression.Convert(Expression, typeof(NxtIniDocument)),
						typeof(NxtIniDocument).GetProperty("Item", [typeof(string)])!,
						Expression.Constant(binder.Name)
					),
					Expression.Convert(value.Expression, typeof(NxtIniSection))
				);
				var restrictions = BindingRestrictions.GetTypeRestriction(Expression, typeof(NxtIniDocument));
				return new DynamicMetaObject(expression, restrictions);
			}
		}
		#endregion IDynamicMetaObjectProvider Members

		public NxtIniSection this[string sectionName]
		{
#pragma warning disable CS8603
			get => _sections[sectionName] is SectionContainer section ? section.Section : default;
#pragma warning restore CS8603
			set => _sections[sectionName] = new SectionContainer { Section = value, Comment = string.Empty };
		}

		public NxtIniSection this[int index]
		{
#pragma warning disable CS8603
			get => _sections[index] is SectionContainer section ? section.Section : default;
#pragma warning restore CS8603
			set => _sections[index] = new SectionContainer { Section = value, Comment = string.Empty };
		}

		public bool ContainsKey(string key)
		{
			return _sections.Contains(key);
		}

		public bool Contains(KeyValuePair<string, NxtIniSection> item)
		{
			return _sections[item.Key] is SectionContainer section && section.Section.Equals(item.Value);
		}

		public void Add(string key, NxtIniSection value, string comment = "")
		{
			if (value is null)
			{
				throw new ArgumentNullException(nameof(value));
			}

			if (string.IsNullOrEmpty(key))
			{
				Insert(0, key, value, comment);
				return;
			}

			var sectionContainer = new SectionContainer
			{
				Section = (NxtIniSection)value.Clone(),
				Comment = comment
			};
			_sections.Add(key, sectionContainer);
		}

		public void Add(string key, NxtIniSection value)
		{
			Add(key, value, string.Empty);
		}

		public void Add(string section, string key, string value, string comment = "")
		{
			Add(section, new NxtIniSection { { key, value } }, comment);
		}

		public void Add(KeyValuePair<string, NxtIniSection> item)
		{
			Add(item.Key, item.Value);
		}

		public void Insert(int index, string key, NxtIniSection value, string comment = "")
		{
			if (string.IsNullOrEmpty(key) && index != 0)
			{
				throw new ArgumentException("The global section must be at index 0.", nameof(key));
			}

			if (!string.IsNullOrEmpty(key) && index == 0 && _sections.Contains(string.Empty))
			{
				throw new ArgumentException("Cannot insert a section at index 0 when a global section exists.", nameof(index));
			}

			_sections.Insert(index, key, new SectionContainer { Section = value, Comment = comment });
		}

		public void Insert(int index, KeyValuePair<string, NxtIniSection> item, string comment = "")
		{
			Insert(index, item.Key, item.Value, comment);
		}

		public bool Remove(string key)
		{
			if (_sections.Contains(key))
			{
				_sections.Remove(key);
				return true;
			}
			else
			{
				return false;
			}
		}

		public bool Remove(KeyValuePair<string, NxtIniSection> item)
		{
			return Remove(item.Key);
		}

		public bool TryGetValue(string key, out NxtIniSection value)
		{
			if (_sections[key] is SectionContainer sectionContainer)
			{
				value = sectionContainer.Section;
				return true;
			}
#pragma warning disable CS8625
			value = null;
#pragma warning restore CS8625
			return false;
		}

		public void CopyTo(KeyValuePair<string, NxtIniSection>[] array, int arrayIndex)
		{
			foreach (string sectionMame in _sections.Keys)
			{
				array[arrayIndex++] = new KeyValuePair<string, NxtIniSection>(sectionMame, ((SectionContainer)_sections[sectionMame]!).Section);
			}
		}

		public void Clear()
		{
			_sections.Clear();
		}

		public IEnumerator<KeyValuePair<string, NxtIniSection>> GetEnumerator()
		{
			foreach (string settingName in _sections.Keys)
			{
				yield return new KeyValuePair<string, NxtIniSection>(settingName, ((SectionContainer)_sections[settingName]!).Section);
			}
		}

		public object Clone()
		{
			var clone = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
			foreach (var sectionName in _sections.Keys)
			{
				var container = (SectionContainer)_sections[sectionName]!;
				clone[sectionName] = new SectionContainer
				{
					Comment = container.Comment,
					Section = (NxtIniSection)container.Section.Clone()
				};
			}
			return clone;
		}

		IEnumerator IEnumerable.GetEnumerator()
		{
			return GetEnumerator();
		}

		public ICollection<string> Keys => [.. _sections.Keys.Cast<string>()];

		public ICollection<NxtIniSection> Values => [.. _sections.Values.Cast<SectionContainer>().Select(c => c.Section)];

		public int Count => _sections.Count;
	}
}
