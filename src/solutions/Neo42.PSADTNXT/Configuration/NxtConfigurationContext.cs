using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using PSADTNXT.Deployment;

namespace PSADTNXT.Configuration
{
	/// <summary>
	/// Provides the data available to configuration callbacks, which are invoked before a deployment session exists.
	/// </summary>
	/// <seealso cref="ConfigurationHookPoint"/>
	public sealed class NxtConfigurationContext
	{
		/// <summary>
		/// Gets the Setup.cfg document of the session. Changes to the document are applied to the session.
		/// </summary>
		public NxtIniDocument SetupCfg { get; }

		/// <summary>
		/// Gets the directory from which the package source files are read.
		/// </summary>
		public string ScriptDirectory { get; }

		/// <summary>
		/// Gets the deployment type of the session.
		/// </summary>
		public NxtDeploymentType DeploymentType { get; }

		/// <summary>
		/// Gets the deployment system that invoked the deployment script.
		/// </summary>
		public string DeploymentSystem { get; }

		/// <summary>
		/// Gets the parameters bound to the deployment script.
		/// </summary>
		public IReadOnlyDictionary<string, object> BoundParameters { get; }

		public NxtConfigurationContext(
			NxtIniDocument setupCfg,
			string scriptDirectory,
			NxtDeploymentType deploymentType,
			string deploymentSystem,
			IDictionary<string, object>? boundParameters)
		{
			if (string.IsNullOrWhiteSpace(scriptDirectory))
			{
				throw new ArgumentException("The script directory must not be null or empty.", nameof(scriptDirectory));
			}

			SetupCfg = setupCfg ?? throw new ArgumentNullException(nameof(setupCfg));
			ScriptDirectory = scriptDirectory;
			DeploymentType = deploymentType ?? throw new ArgumentNullException(nameof(deploymentType));
			DeploymentSystem = deploymentSystem ?? string.Empty;
			BoundParameters = new ReadOnlyDictionary<string, object>(
				boundParameters is null
					? new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase)
					: new Dictionary<string, object>(boundParameters, StringComparer.OrdinalIgnoreCase));
		}
	}
}
