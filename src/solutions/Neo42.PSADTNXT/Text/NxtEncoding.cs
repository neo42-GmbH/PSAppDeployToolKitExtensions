using System;
using System.Globalization;
using System.Text;

namespace PSADTNXT.Text
{
	public static class NxtEncoding
	{
		/// <summary>
		/// Translates a FileEncoding enum value to the corresponding System.Text.Encoding instance.
		/// </summary>
		/// <param name="encoding">The FileEncoding enum value to translate.</param>
		/// <returns>The corresponding System.Text.Encoding instance.</returns>
		/// <exception cref="ArgumentOutOfRangeException">Thrown when the provided FileEncoding value is not supported.</exception>
		public static Encoding GetEncoding(FileEncoding encoding)
		{
#pragma warning disable SYSLIB0001 // Accept old encodings
			return encoding switch
			{
				FileEncoding.Default => Encoding.Default,
				FileEncoding.OEM => Encoding.GetEncoding(CultureInfo.InvariantCulture.TextInfo.OEMCodePage),
				FileEncoding.ASCII => new ASCIIEncoding(),
				FileEncoding.ANSI => Encoding.GetEncoding(CultureInfo.InvariantCulture.TextInfo.ANSICodePage),
				FileEncoding.UTF7 => new UTF7Encoding(false),
				FileEncoding.UTF7WithBOM => new UTF7Encoding(true),
				FileEncoding.UTF8 => new UTF8Encoding(false),
				FileEncoding.UTF8WithBOM => new UTF8Encoding(true),
				FileEncoding.Unicode => new UnicodeEncoding(false, false),
				FileEncoding.UnicodeWithBOM => new UnicodeEncoding(false, true),
				FileEncoding.BigEndianUnicode => new UnicodeEncoding(true, false),
				FileEncoding.BigEndianUnicodeWithBOM => new UnicodeEncoding(true, true),
				FileEncoding.UTF32 => new UTF32Encoding(false, false),
				FileEncoding.UTF32WithBOM => new UTF32Encoding(false, true),
				FileEncoding.BigEndianUTF32 => new UTF32Encoding(true, false),
				FileEncoding.BigEndianUTF32WithBOM => new UTF32Encoding(true, true),
				_ => throw new ArgumentOutOfRangeException(nameof(encoding), encoding, "Unsupported encoding type."),
			};
#pragma warning restore SYSLIB0001 // Accept old encodings
		}

		/// <summary>
		/// Translates a System.Text.Encoding instance to the corresponding FileEncoding enum value.
		/// </summary>
		/// <param name="encoding">The System.Text.Encoding instance to translate.</param>
		/// <returns>The corresponding FileEncoding enum value.</returns>
		/// <exception cref="ArgumentOutOfRangeException">Thrown when the provided Encoding instance is not supported.	</exception>
		public static FileEncoding GetEncodingName(Encoding encoding)
		{
			var hasBOM = encoding.GetPreamble().Length > 0;
			return encoding.CodePage switch
			{
				437 => FileEncoding.OEM,
				20127 => FileEncoding.ASCII,
				1252 => FileEncoding.ANSI,
				65000 => hasBOM ? FileEncoding.UTF7WithBOM : FileEncoding.UTF7,
				65001 => hasBOM ? FileEncoding.UTF8WithBOM : FileEncoding.UTF8,
				1200 => hasBOM ? FileEncoding.UnicodeWithBOM : FileEncoding.Unicode,
				1201 => hasBOM ? FileEncoding.BigEndianUnicodeWithBOM : FileEncoding.BigEndianUnicode,
				12000 => hasBOM ? FileEncoding.UTF32WithBOM : FileEncoding.UTF32,
				12001 => hasBOM ? FileEncoding.BigEndianUTF32WithBOM : FileEncoding.BigEndianUTF32,
				_ => encoding.CodePage == Encoding.Default.CodePage
					? FileEncoding.Default
					: throw new ArgumentOutOfRangeException(nameof(encoding), encoding, "Unsupported encoding type.")
			};
		}
	}
}
