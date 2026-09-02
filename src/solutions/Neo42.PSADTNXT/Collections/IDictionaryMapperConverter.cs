using System.Reflection;

namespace PSADTNXT.Collections
{
	public interface IDictionaryMapperConverter
	{
		bool TryConvert(object value, PropertyInfo member, out object? result);
	}
}
