using System;
using System.Collections.Generic;
using System.Management.Automation;
using PSADT.Module;
using PSADTNXT.Deployment;

namespace PSADTNXT.Foundation
{
	public sealed class NxtDeploymentSession : DeploymentSession
	{
		/// <summary>
		/// All Neo42.Extension functionality is nested in this instance to keep the session clean and avoid future conflicts.
		/// </summary>
		/// <value>The <see cref="NxtDeploymentExtension"/> instance for this deployment session.</value>
		public NxtDeploymentExtension NXT { get; }

		/// <summary>
		/// Initializes a new instance of the <see cref="NxtDeploymentSession"/> class.
		/// The constructor is sanitized to match the constructor of the <see cref="DeploymentSession"/> class and
		/// parameters are updated with values from the package config.
		/// </summary>
		/// <param name="parameters">The parameters to initialize the session with</param>
		/// <param name="noExitOnClose">Whether to exit the session on close.</param>
		/// <param name="callerSessionState">The caller session state to use.</param>
		/// <note>This constructor must match the constructor of the <see cref="DeploymentSession"/> class.</note>
		public NxtDeploymentSession(IReadOnlyDictionary<string, object>? parameters = null, bool? noExitOnClose = null, SessionState? callerSessionState = null)
			: base(parameters, noExitOnClose, callerSessionState)
		{
			WriteLogEntry($"Initializing Neo42 Extensions [{GetType().Assembly.GetName().Version}] for PSAppDeployToolkit.");
			NXT = parameters == null
				? throw new ArgumentNullException(nameof(parameters), "Parameters cannot be null for NxtDeploymentSession.")
				: new NxtDeploymentExtension(this, parameters);
		}
	}
}
