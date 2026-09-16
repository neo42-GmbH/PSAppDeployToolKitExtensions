using PSADTNXT.Text;
using System;
using System.Management.Automation;
using System.Text;

namespace PSADTNXT.Attributes
{
	/// <summary>
	/// Transforms objects into a <see cref="Encoding"/>.
	/// </summary>
	public sealed class NxtEncodingTransformationAttribute : ArgumentTransformationAttribute
	{
		public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
		{
			var baseObj = (inputData is PSObject psObj ? psObj.BaseObject : inputData) ?? throw new ArgumentNullException(paramName: nameof(inputData), "Cannot transform null to IdentityReference.");

			if (baseObj is Encoding enc)
			{
				return enc;
			}
			if (baseObj is FileEncoding encoding)
			{
				return NxtEncoding.GetEncoding(encoding);
			}
			if (baseObj is string strEncoding)
			{
				if (Enum.TryParse<FileEncoding>(strEncoding, true, out var parsedNxtEncoding))
				{
					return NxtEncoding.GetEncoding(parsedNxtEncoding);
				}
				else if (TryParseEncoding(strEncoding, out var parsedNativeEncoding))
				{
					return parsedNativeEncoding!;
				}
				else
				{
					throw new ArgumentException("The input string cannot be parsed as an Encoding.", nameof(inputData));
				}
			}

			throw new ArgumentException("Input data must be of type FileEncoding or Encoding.", nameof(inputData));
		}

		private static bool TryParseEncoding(string encodingName, out Encoding? encoding)
		{
			try
			{
				encoding = Encoding.GetEncoding(encodingName);
				return true;
			}
			catch (ArgumentException)
			{
				encoding = null;
				return false;
			}
		}
	}
}
