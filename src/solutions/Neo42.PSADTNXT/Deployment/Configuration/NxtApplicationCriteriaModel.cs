using System.Management.Automation;
using PSADTNXT.Application;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtApplicationCriteriaModel
	{
		public ApplicationStore Store { get; set; } = ApplicationStore.ARP;

		public string? Identifier { get; set; }

		[ValidScriptBlock(Strict = true, AllowedVariables = ["_", "PSItem"])]
		public ScriptBlock? Filter { get; set; }
	}
}
