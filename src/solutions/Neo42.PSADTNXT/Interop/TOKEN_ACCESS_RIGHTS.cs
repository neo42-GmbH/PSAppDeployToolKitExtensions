namespace PSADTNXT.Interop
{
#pragma warning disable CA1008
	public enum TOKEN_ACCESS_RIGHTS : int
#pragma warning restore CA1008
	{
		TokenAssignPrimary = 0x0001,
		TokenDuplicate = 0x0002,
		TokenImpersonate = 0x0004,
		TokenQuery = 0x0008,
		TokenQuerySource = 0x0010,
		TokenAdjustPrivileges = 0x0020,
		TokenAdjustGroups = 0x0040,
		TokenAdjustDefault = 0x0080,
		TokenAdjustSessionId = 0x0100,
		StandardRightsRequired = 0x000F0000,

		All = StandardRightsRequired | TokenAssignPrimary | TokenDuplicate | TokenImpersonate | TokenQuery | TokenQuerySource | TokenAdjustPrivileges | TokenAdjustGroups | TokenAdjustDefault | TokenAdjustSessionId
	}
}
