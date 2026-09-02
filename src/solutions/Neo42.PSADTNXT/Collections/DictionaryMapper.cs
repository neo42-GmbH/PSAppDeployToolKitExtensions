using System;
using System.Collections;
using System.Linq;
using System.Reflection;
using PSADTNXT.Extensions;

namespace PSADTNXT.Collections
{
	internal static class DictionaryMapper
	{
		private static readonly Lazy<DictionaryMapperDefaultConverter> _defaultConverter = new(() => new DictionaryMapperDefaultConverter());

		public static T Create<T>(IDictionary source) where T : new()
		{
			var instance = new T();
			PopulateObject(source, instance);
			return instance;
		}

#pragma warning disable CA1502
		public static void PopulateObject(IDictionary source, object instance)
#pragma warning restore CA1502
		{
			if (source is null)
			{
				throw new ArgumentNullException(nameof(source));
			}

			if (instance is null)
			{
				throw new ArgumentNullException(nameof(instance));
			}

			if (instance.GetType().IsPrimitive || instance is string)
			{
				throw new ArgumentException("The instance to populate must not be a primitve or string.", nameof(instance));
			}

			var properties = instance.GetType()
				.GetProperties(BindingFlags.Public | BindingFlags.Instance)
				.OrderBy(p => p.GetCustomAttribute<DictionaryMapperAttribute>()?.Order ?? 0);

			foreach (var property in properties)
			{
				var name = property.GetCustomAttribute<DictionaryMapperAttribute>()?.PropertyName ?? property.Name;

				// Only populate if the dictionary contains the key
				if (!source.Contains(name))
				{
					continue;
				}

				var value = ApplyConverter(source[name], property);

				// Handle null values
				if (value == null)
				{
					if (!property.PropertyType.IsValueType || Nullable.GetUnderlyingType(property.PropertyType) != null)
					{
						property.SetValue(instance, null);
					}
					continue;
				}

				// Directly assignable types
				if (value.GetType() == property.PropertyType || property.PropertyType.IsAssignableFrom(value.GetType()))
				{
					property.SetValue(instance, value);
					continue;
				}

				// Nested object population
				if (!property.PropertyType.IsPrimitive && property.PropertyType != typeof(string) && value is IDictionary dictionary)
				{
					if (property.GetValue(instance) is not object nestedInstance)
					{
						nestedInstance = Activator.CreateInstance(property.PropertyType)
							?? throw new InvalidOperationException($"Could not create instance of type '{property.PropertyType}' as required by property '{property.Name}'.");
						property.SetValue(instance, nestedInstance);
					}

					if (property.PropertyType.Implements(typeof(IDictionary)))
					{
						PopulateDictionary(dictionary, (IDictionary)nestedInstance);
					}
					else
					{
						PopulateObject(dictionary, nestedInstance);
					}
					continue;
				}

				// Collection population
				if (property.PropertyType.Implements(typeof(IList)) && value.GetType().Implements(typeof(IList)))
				{
					if (property.GetValue(instance) is not IList collection || property.PropertyType.IsArray)
					{
						collection = property.PropertyType.IsArray
							? Array.CreateInstance(property.PropertyType.GetElementType()!, ((IList)value).Count)
							: (IList)Activator.CreateInstance(property.PropertyType)!;

						property.SetValue(instance, collection);
					}
					PopulateCollection((IList)value, collection);
					continue;
				}

				// Fallback to default converter
				if (_defaultConverter.Value.TryConvert(value, property, out var defaultConvertedValue))
				{
					property.SetValue(instance, defaultConvertedValue);
					continue;
				}

				throw new InvalidOperationException($"Cannot map value of type '{value.GetType().FullName}' to property '{property.Name}' of type '{property.PropertyType.FullName}'.");
			}
		}

		private static void PopulateCollection(IList source, IList instance)
		{
			if (source.Count == 0)
			{
				return;
			}

			if (instance.IsFixedSize && instance.Count != source.Count)
			{
				throw new InvalidOperationException($"Cannot populate fixed size collection of type {instance.GetType()} because the source collection has a different count.");
			}

			var isArray = instance.GetType().IsArray;
			var itemType = (isArray ? instance.GetType().GetElementType() : instance.GetType().GetGenericArguments().FirstOrDefault()) ?? typeof(object);

			for (var i = 0; i < source.Count; i++)
			{
				var item = source[i];
				object? result;
				if (itemType.IsAssignableFrom(item?.GetType()))
				{
					result = item;
				}
				else if (item is null)
				{
					throw new InvalidCastException($"Null cannot be assigned to {itemType}");
				}
				else if (!itemType.IsPrimitive && item is IDictionary itemDict)
				{
					var itemInstance = Activator.CreateInstance(itemType)!;
					PopulateObject(itemDict, itemInstance);
					result = itemInstance;
				}
				else if (source[i] is IList itemList)
				{
					var collectionInstance = itemType.IsArray
						? Array.CreateInstance(itemType, itemList.Count)
						: (IList)Activator.CreateInstance(itemType)!;

					PopulateCollection(itemList, collectionInstance);
					result = collectionInstance;
				}
				else
				{
					throw new InvalidOperationException($"Cannot map collection item of type '{item.GetType().FullName}' to collection item type '{itemType.FullName}'.");
				}

				if (instance.IsFixedSize)
				{
					instance[i] = result;
				}
				else
				{
					_ = instance.Add(result);
				}
			}
		}

		private static void PopulateDictionary(IDictionary source, IDictionary instance)
		{
			var valueType = instance.GetType().IsGenericType
				? instance.GetType().GetGenericArguments()[1]
				: typeof(object);

			foreach (var key in source.Keys)
			{
				var value = source[key];
				if (valueType.IsAssignableFrom(value?.GetType()))
				{
					instance[key] = value;
				}
				else if (value is null)
				{
					throw new InvalidCastException($"Null cannot be assigned to {valueType}");
				}
				else if (!valueType.IsPrimitive && value is IDictionary valueDict)
				{
					var valueInstance = Activator.CreateInstance(valueType)!;
					PopulateObject(valueDict, valueInstance);
					instance[key] = valueInstance;
				}
				else if (value is IList valueList)
				{
					var collectionInstance = valueType.IsArray
						? Array.CreateInstance(valueType, valueList.Count)
						: (IList)Activator.CreateInstance(valueType)!;

					PopulateCollection(valueList, collectionInstance);
					instance[key] = collectionInstance;
				}
				else
				{
					throw new InvalidOperationException($"Cannot map dictionary value of type '{value.GetType().FullName}' to dictionary value type '{valueType.FullName}'.");
				}
			}
		}

		private static object? ApplyConverter(object? value, PropertyInfo property)
		{
			return value is null
				|| property.GetCustomAttribute<DictionaryMapperAttribute>() is not DictionaryMapperAttribute attribute
				|| attribute.Converter is null
				? value
				: Activator.CreateInstance(attribute.Converter, attribute.ConverterArguments ?? []) is not IDictionaryMapperConverter converter
				? throw new InvalidOperationException($"The converter '{attribute.Converter.FullName}' could not be created with the provided arguments.")
				: !converter.TryConvert(value, property, out var converterValue)
				? throw new InvalidOperationException($"The converter '{attribute.Converter.FullName}' failed to convert the value for property '{property.Name}'.")
				: converterValue;
		}
	}
}
