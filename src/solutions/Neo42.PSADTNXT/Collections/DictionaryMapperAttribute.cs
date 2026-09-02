using System;

namespace PSADTNXT.Collections
{
	/// Attribute to specify the import order of a module.
	[AttributeUsage(AttributeTargets.Property, Inherited = false, AllowMultiple = false)]
	internal class DictionaryMapperAttribute : Attribute
	{
		public string? PropertyName { get; set; }
		public int Order { get; set; }
		public Type? Converter { get; set; }
		public object[]? ConverterArguments { get; set; }

		public DictionaryMapperAttribute()
		{
		}
	}
}
