using System.Collections.Generic;

namespace PSADTNXT.Deployment
{
	public sealed class NxtUninstallationInstructions
	{
		public DeploymentMethod? Method { get; set; }

		public string Target { get; set; } = string.Empty;

		public string Arguments { get; set; } = string.Empty;

		public bool Defaults { get; set; }

		public string LogName { get; set; } = string.Empty;

		public List<int> SuccessCodes { get; } = [0];

		public List<int> RebootCodes { get; } = [1641, 3010];

		public bool IgnoreExitCodes { get; set; }

		public RebootAction Reboot { get; set; }

		public List<INxtAwaiter> Awaiters { get; } = [];

		public bool UserPart { get; set; }

		internal NxtUninstallationInstructions() { }

		public override string ToString()
		{
			return $"Neo42 {Method?.ToString() ?? "Custom"} uninstallation instructions.";
		}
	}
}
