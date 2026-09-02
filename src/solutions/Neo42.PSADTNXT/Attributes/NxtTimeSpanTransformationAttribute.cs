using System;
using System.Globalization;
using System.Management.Automation;

namespace PSADTNXT.Attributes
{
	/// <summary>
	/// Transforms numerical values into a <see cref="TimeSpan"/> by treating the value as seconds.
	/// </summary>
	/// <remarks>
	/// This attribute ensures numeric input is interpreted as seconds rather than PowerShell's default tick behavior
	/// for implicit conversions to <see cref="TimeSpan"/>.
	/// </remarks>
	[Obsolete("Backport from PSADT 4.2 for compatibility. Migrate once on 4.2")]
	public sealed class NxtTimeSpanTransformationAttribute() : ArgumentTransformationAttribute
	{
		/// <summary>
		/// Transforms the input value into a <see cref="TimeSpan"/>.
		/// </summary>
		/// <param name="engineIntrinsics">The PowerShell engine intrinsics.</param>
		/// <param name="inputData">The input value to transform.</param>
		/// <returns>A <see cref="TimeSpan"/> value derived from the input.</returns>
		/// <exception cref="ArgumentNullException">Thrown when the input value is null.</exception>
		/// <exception cref="ArgumentException">Thrown when the input value cannot be transformed into a TimeSpan.</exception>
		public override object Transform(EngineIntrinsics engineIntrinsics, object? inputData)
		{
			var baseObj = inputData is PSObject psObj ? psObj.BaseObject : inputData;

			if (baseObj is null)
			{
				throw new ArgumentNullException(paramName: nameof(inputData), "Cannot transform null to TimeSpan.");
			}
			if (baseObj is TimeSpan timeSpan)
			{
				return timeSpan;
			}
			if (baseObj is string valueAsString)
			{
				if (TimeSpan.TryParse(valueAsString, FormatProvider, out TimeSpan parsedTimeSpan))
				{
					return parsedTimeSpan;
				}
				if (long.TryParse(valueAsString, NumberStyles.Integer, CultureInfo.InvariantCulture, out long parsedIntegerSeconds))
				{
					return TimeSpan.FromSeconds(parsedIntegerSeconds);
				}
				if (double.TryParse(valueAsString, NumberStyles.Float | NumberStyles.AllowThousands, CultureInfo.InvariantCulture, out double parsedNumericalSeconds))
				{
					return TimeSpan.FromSeconds(parsedNumericalSeconds);
				}
			}
			return !TryGetNumericalSeconds(baseObj, out double seconds)
				? throw new ArgumentException($"Cannot transform value of type '{baseObj.GetType().FullName}' to TimeSpan.")
				: TimeSpan.FromSeconds(seconds);
		}

		/// <summary>
		/// Attempts to extract a numerical value representing seconds from the specified input data.
		/// </summary>
		/// <param name="inputData">The input object to evaluate. Supported types are sbyte, byte, short, ushort, int, uint, long, ulong, float,
		/// double, and decimal.</param>
		/// <param name="seconds">When this method returns, contains the extracted number of seconds if the conversion succeeded; otherwise,
		/// zero.</param>
		/// <returns>true if the input data was successfully converted to a numerical value representing seconds; otherwise,
		/// false.</returns>
		private static bool TryGetNumericalSeconds(object inputData, out double seconds)
		{
			switch (inputData)
			{
				case sbyte value:
					{
						seconds = value;
						return true;
					}

				case byte value:
					{
						seconds = value;
						return true;
					}

				case short value:
					{
						seconds = value;
						return true;
					}

				case ushort value:
					{
						seconds = value;
						return true;
					}

				case int value:
					{
						seconds = value;
						return true;
					}

				case uint value:
					{
						seconds = value;
						return true;
					}

				case long value:
					{
						seconds = value;
						return true;
					}

				case ulong value:
					{
						seconds = value;
						return true;
					}

				case float value:
					{
						seconds = value;
						return true;
					}

				case double value:
					{
						seconds = value;
						return true;
					}

				case decimal value:
					try
					{
						seconds = (double)value;
						return true;
					}
					catch (OverflowException)
					{
						seconds = default;
						return false;
					}

				default:
					{
						seconds = default;
						return false;
					}
			}
		}

		/// <summary>
		/// Represents the format provider associated with the current context.
		/// </summary>
		public IFormatProvider FormatProvider { get; } = CultureInfo.CurrentCulture;
	}
}
