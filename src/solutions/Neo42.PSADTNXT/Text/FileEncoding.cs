namespace PSADTNXT.Text
{
	/// <summary>
	/// Supported file encodings for text files.
	/// </summary>
	/// <remarks>
	/// Translation is handled by <see cref="NxtEncoding.GetEncoding(FileEncoding)"/>.
	/// </remarks>
	public enum FileEncoding
	{
		Default,
		OEM,
		ASCII,
		ANSI,
		UTF7,
		UTF7WithBOM,
		UTF8,
		UTF8WithBOM,
		Unicode,
		UnicodeWithBOM,
		BigEndianUnicode,
		BigEndianUnicodeWithBOM,
		UTF32,
		UTF32WithBOM,
		BigEndianUTF32,
		BigEndianUTF32WithBOM
	}
}
