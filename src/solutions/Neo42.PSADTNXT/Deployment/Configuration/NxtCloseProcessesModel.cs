using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;
using PSADTNXT.ProcessManagement;

namespace PSADTNXT.Deployment.Configuration
{
	public sealed record NxtCloseProcessesModel
	{
		[Required]
		[ValidPath]
		public string Name { get; set; } = null!;

		public string? Description { get; set; }

		public bool AllowBlocking { get; set; } = true;

		public ReopenMode ReopenMode { get; set; } = ReopenMode.None;
	}
}
