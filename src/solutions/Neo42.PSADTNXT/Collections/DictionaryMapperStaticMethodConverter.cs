using System;
using System.Reflection;

namespace PSADTNXT.Collections
{
	internal class DictionaryMapperStaticMethodConverter<T>(string method) : IDictionaryMapperConverter
	{
		private readonly string _methodName = method ?? throw new ArgumentNullException(nameof(method));

		public bool TryConvert(object value, PropertyInfo member, out object? result)
		{
			result = null;
			try
			{
				var invokeResult = typeof(T)
					.GetMethod(_methodName, BindingFlags.Public | BindingFlags.Static)
					?.Invoke(null, [value]);

				if (invokeResult is not null and T)
				{
					result = (T)invokeResult;
					return true;
				}
				return false;
			}
			catch
			{
				return false;
			}
		}
	}
}
