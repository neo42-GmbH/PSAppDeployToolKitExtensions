using System.Reflection;

namespace PSADTNXT.Collections
{
	internal interface IDictionaryMapperConverter
	{
		bool TryConvert(object value, PropertyInfo member, out object? result);
	}
}
