using System;
using System.Reflection;
using PSADTNXT.Extensions;

namespace PSADTNXT.Collections
{
	internal class DictionaryMapperDefaultConverter : IDictionaryMapperConverter
	{
		public bool TryConvert(object value, PropertyInfo member, out object? result)
		{
			result = null;
			if (value == null)
			{
				return false;
			}

			var valueType = value.GetType();
			var propertyType = Nullable.GetUnderlyingType(member.PropertyType) ?? member.PropertyType;

			if (propertyType.IsEnum)
			{
				try
				{
					result = Enum.Parse(propertyType, value.ToString()!, true);
					return true;
				}
				catch
				{
					return false;
				}
			}
			else if (propertyType.Implements(typeof(IConvertible)) && valueType.Implements(typeof(IConvertible)))
			{
				try
				{
					result = Convert.ChangeType(value, propertyType);
					return true;
				}
				catch
				{
					return false;
				}
			}
			else if (propertyType.GetConstructor([valueType]) is ConstructorInfo ctor)
			{
				try
				{
					result = ctor.Invoke([value]);
					return true;
				}
				catch
				{
					return false;
				}
			}
			else if (propertyType.GetMethod("TryParse", [valueType, propertyType.MakeByRefType()]) is MethodInfo parseMethod)
			{
				var args = new object?[] { value, null };
				if (parseMethod.Invoke(null, args) is bool success && success)
				{
					result = args[1];
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
		}
	}
}
