using PSADTNXT.Text;
using System;
using System.Management.Automation;
using System.Text;

namespace PSADTNXT.Attributes
{
	/// <summary>
	/// Transforms objects into a <see cref="Encoding"/>.
	/// </summary>
	public class NxtEncodingTransformationAttribute : ArgumentTransformationAttribute
	{
		public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
		{
			if (inputData is PSObject psObject)
			{
				inputData = psObject.BaseObject;
			}
			if (inputData is null)
			{
				throw new ArgumentNullException(nameof(inputData), "Cannot transform null into an Encoding");
			}

			if (inputData is Encoding enc)
			{
				return enc;
			}
			if (inputData is FileEncoding encoding)
			{
				return NxtEncoding.GetEncoding(encoding);
			}
			else if (inputData is string strEncoding)
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
			else
			{
				throw new ArgumentException("Input data must be of type FileEncoding or Encoding.", nameof(inputData));
			}
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
