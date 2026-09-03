using System;

namespace PSADTNXT.Deployment
{
	/// <summary>
	/// Exception used to control the flow of the deployment process.
	/// </summary>
	/// <remarks
	/// This exception is only intended to be used in PowerShell directly, and not in the C# code.
	/// </remarks>
	public sealed class NxtDeploymentCancelException(string message, Exception? innerException = null) : Exception(message, innerException) { }
}
