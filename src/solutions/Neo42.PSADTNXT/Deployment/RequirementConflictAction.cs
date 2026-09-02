namespace PSADTNXT.Deployment
{
	/// <summary>
	/// These values map to <see cref="PSADT.Module.LogSeverity"/> for easier logging actions
	/// </summary>
	public enum RequirementConflictAction : int
	{
		Uninstall = 0,
		Continue = 1,
		Warn = 2,
		Fail = 3
	}
}
