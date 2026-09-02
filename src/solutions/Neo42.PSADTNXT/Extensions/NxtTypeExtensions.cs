using System;
using System.Collections.Generic;
using System.Linq;

namespace PSADTNXT.Extensions
{
	public static class NxtTypeExtensions
	{
		/// <summary>
		/// All integer types.
		/// </summary>
		private static readonly IReadOnlyCollection<Type> _integerTypes =
		[
			typeof(sbyte),
			typeof(byte),
			typeof(short),
			typeof(ushort),
			typeof(int),
			typeof(uint),
			typeof(long),
			typeof(ulong)
		];

		/// <summary>
		/// All floating point types.
		/// </summary>
		private static readonly IReadOnlyCollection<Type> _floatingPointTypes =
		[
			typeof(float),
			typeof(double),
			typeof(decimal)
		];

		/// <summary>
		/// Checks if the given type implements the given interface type.
		/// </summary>
		/// <param name="type"></param>
		/// <param name="interfaceType"></param>
		/// <returns>True if the type implements the interface type, otherwise false.</returns>
		public static bool Implements(this Type type, Type interfaceType)
		{
			if (Nullable.GetUnderlyingType(type) is Type nullableType)
			{
				type = nullableType;
			}

			return interfaceType.IsGenericTypeDefinition
				? type.GetInterfaces().Any(i => i.IsGenericType && i.GetGenericTypeDefinition() == interfaceType)
				: interfaceType.IsAssignableFrom(type);
		}

		/// <summary>
		/// Checks if the given object is a number type.
		/// </summary>
		/// <param name="value">The type to check.</param>
		/// <param name="floatingPoints">If true, floating point types are also considered numbers.</param>
		/// <returns>True if the type is a number type, otherwise false.</returns>
		public static bool IsNumber(this Type value, bool floatingPoints = true)
		{
			return _integerTypes.Contains(value)
				|| (floatingPoints && _floatingPointTypes.Contains(value));
		}

		/// <summary>
		/// Quick check if Type is nullable.
		/// </summary>
		/// <param name="type">Type to check</param>
		/// <returns>True if type is nullable</returns>
		public static bool IsNullable(this Type type)
		{
			return Nullable.GetUnderlyingType(type) != null;
		}
	}
}
