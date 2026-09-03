using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text.RegularExpressions;
using Microsoft.Win32;
using PSADT.Module;
using PSADT.ProcessManagement;
using PSADTNXT.Application;
using PSADTNXT.Configuration;
using PSADTNXT.Deployment.Configuration;
using PSADTNXT.Extensions;
using PSADTNXT.Foundation;
using PSADTNXT.IO;
using PSADTNXT.ProcessManagement;

namespace PSADTNXT.Deployment
{
#pragma warning disable CA1506
	public sealed class NxtDeploymentExtension
#pragma warning restore CA1506
	{
		private readonly NxtDeploymentSession _session;

		[Hidden]
		[Obsolete("Exposed in PSADT 4.2 by default.")]
		public SessionState? DeployAppScriptSessionState { get; set; }

		[Hidden]
		public FileInfo DeployAppScript { get; }

		public NxtDeploymentType DeploymentType { get; }

		public string DeploymentSystem { get; }

		public NxtPackageMetadata Package { get; }

		public List<NxtRequirement> Requirements { get; }

		public NxtInstallationDetection Detection { get; }

		public NxtSoftMigration SoftMigration { get; }

		public List<NxtCloseProcess> CloseProcesses { get; }

		// Do not show, might be implemented upstream
		[Hidden]
		public List<NxtClosedProcess> ClosedProcesses { get; } = [];

		public List<NxtShortcutOperation> ManagedShortcuts { get; }

		public List<NxtApplicationCriteria> ManagedApplications { get; }

		public string UserPartRevision { get; }

		public DirectoryInfo? InstallLocation { get; set; }

		public NxtInstallationInstructions Install { get; }

		[Hidden]
		[Obsolete("Replaced by shortend Install property")]
		public NxtInstallationInstructions Installation => Install;

		public NxtUninstallationInstructions Uninstall { get; }

		[Hidden]
		[Obsolete("Replaced by shortend Uninstall property")]
		public NxtUninstallationInstructions Uninstallation => Uninstall;

		public List<ProcessResult> ProcessResults { get; } = [];

		public NxtIniDocument SetupCfg { get; }

		public Dictionary<string, object> Variables { get; }

		public NxtDeploymentExtension(NxtDeploymentSession session, IReadOnlyDictionary<string, object> parameters)
		{
			_session = session ?? throw new ArgumentNullException(nameof(session));

			if (string.IsNullOrWhiteSpace(_session.AppVendor) || string.IsNullOrWhiteSpace(_session.AppName))
			{
				throw new InvalidDataException("AppVendor and AppName are required parameters for neo42 session construction.");
			}

			SetupCfg = parameters["SetupCfg"] is NxtIniDocument setupCfg ? setupCfg : throw new ArgumentException("SetupCfg parameter is required and must be of type NxtIniDocument.");
			DeploymentType = parameters["NxtDeploymentType"] is NxtDeploymentType nxtDeploymentType ? nxtDeploymentType : _session.DeploymentType;
			DeploymentSystem = parameters["DeploymentSystem"] as string ?? "Unknown";
			DeployAppScript = parameters["DeployAppScriptPath"] is string scriptPath ? new(scriptPath) : throw new ArgumentException("DeployAppScriptPath parameter is required.");

			var packageConfig = parameters["PackageConfig"] is NxtPackageConfigurationModel config ? config : throw new ArgumentException("PackageConfig parameter is required and must be of type NxtPackageConfigurationModel.");
			var nxtConfig = ModuleDatabase.GetConfig()["NXT"] as Hashtable;
			var nxtToolkitConfig = nxtConfig?["Toolkit"] as Hashtable;
			var packageRootDir = InitializePackageRootDirectory(packageConfig.Package.DirectoryName, packageConfig.Package.KeyName, DeploymentType);
			var appendVersion = nxtToolkitConfig?["AppendVersionToPackageName"] is bool append && append;

			Package = GetPackageMetadata(packageConfig, packageRootDir, appendVersion);
			Requirements = GetPackageRequirements(packageConfig);
			Detection = GetInstallDetection(packageConfig);
			SoftMigration = GetSoftMigration(packageConfig);
			CloseProcesses = GetCloseProcesses(packageConfig);
			ManagedShortcuts = GetManagedShortcuts(packageConfig);
			ManagedApplications = config.ManagedApplications?.Select(ConvertToCriteria).ToList() ?? [];
			UserPartRevision = packageConfig.Package.Version.Replace(".", ",") + string.Concat(Enumerable.Repeat(",0", 3 - packageConfig.Package.Version.Count(c => c == '.')));
			InstallLocation = !string.IsNullOrWhiteSpace(packageConfig.Deployment?.InstallLocation) ? new(packageConfig.Deployment!.InstallLocation) : null;
			Install = GetInstallInstructions(packageConfig);
			Uninstall = GetUninstallInstructions(packageConfig);
			Variables = new(packageConfig.Variables ?? [], StringComparer.OrdinalIgnoreCase);

			_session.WriteLogEntry($"Package cache directory resides in [{Package.Directory.FullName}].");
		}

		private NxtPackageMetadata GetPackageMetadata(NxtPackageConfigurationModel config, DirectoryInfo packageRootDir, bool appendVersion)
		{
			return new NxtPackageMetadata(
				Guid.Parse(config.Package.GUID),
				(string.IsNullOrWhiteSpace(config.Package.DisplayName) ? $"{config.Package.Vendor} {config.Package.Name}" : config.Package.DisplayName) + (appendVersion ? $" {config.Package.Version}" : string.Empty),
				new DirectoryInfo(Path.Combine(packageRootDir.FullName, _session.AppVendor!, _session.AppName!, config.Package.Version.ToString())),
				packageRootDir,
				config.Package.KeyName,
				config.Package.UninstallOld,
				config.Package.ApplicationEntry
			);
		}

		private NxtApplicationCriteria ConvertToCriteria(NxtApplicationCriteriaModel model)
		{
			// Due to the way PowerShell handles ScriptBlocks, we need to create a new unbound ScriptBlock instance to avoid issues with runspace binding when the criteria is evaluated in a different context than it was created in.
			var filter = !string.IsNullOrWhiteSpace(model.Filter?.ToString()) ? GetUnboundScriptBlock(model.Filter!) : null;

			if (filter != null && !string.IsNullOrWhiteSpace(model.Identifier))
			{
				return new NxtApplicationCriteria(model.Store, model.Identifier!, filter);
			}
			else if (filter != null)
			{
				return new NxtApplicationCriteria(model.Store, filter);
			}
			else if (!string.IsNullOrWhiteSpace(model.Identifier))
			{
				return new NxtApplicationCriteria(model.Store, model.Identifier!);
			}
			else
			{
				throw new ArgumentException("At least one of 'Identifier' or 'Filter' must be provided in the application criteria model.");
			}
		}

		private List<NxtRequirement> GetPackageRequirements(NxtPackageConfigurationModel config)
		{
			return config.Requirements?.Select(
				req => new NxtRequirement(
					ConvertToCriteria(req.Criteria),
					req.DesiredState,
					req.OnConflict,
					req.ErrorMessage ?? $"An application was not {req.DesiredState.ToString().ToLower()} as required by this deployment."
				)
			).ToList() ?? [];
		}

		private NxtInstallationDetection GetInstallDetection(NxtPackageConfigurationModel config)
		{
			return new NxtInstallationDetection()
			{
				Enabled = config.Detection?.Enabled ?? false,
				TargetVersion = config.Detection?.UsePackageVersion == true
					? new(config.Package.Version)
					: !string.IsNullOrWhiteSpace(config.Detection?.Version)
						? new(config.Detection!.Version!)
						: null,
				Criteria = config.Detection?.Criteria is NxtApplicationCriteriaModel criteria
					? ConvertToCriteria(criteria)
					: null
			};
		}

		private NxtSoftMigration GetSoftMigration(NxtPackageConfigurationModel config)
		{
			return new NxtSoftMigration
			{
				Enabled = config.SoftMigration?.Enabled ?? false,
				Mode = config.SoftMigration?.Mode ?? SoftMigrationDetectionMode.Custom,
				Target = config.SoftMigration?.Target,
				Version = config.SoftMigration?.UsePackageVersion == true
					? new(config.Package.Version)
					: !string.IsNullOrWhiteSpace(config.SoftMigration?.Version)
						? new(config.SoftMigration!.Version!)
						: config.SoftMigration?.Mode == SoftMigrationDetectionMode.Detection
							? Detection.TargetVersion
							: null
			};
		}

		private List<NxtCloseProcess> GetCloseProcesses(NxtPackageConfigurationModel config)
		{
			return config.CloseProcesses?.Select(
				proc => new NxtCloseProcess(
					proc.Name,
					proc.Description ?? string.Empty,
					proc.AllowBlocking,
					proc.ReopenMode
				)
			).ToList() ?? [];
		}

		private List<NxtShortcutOperation> GetManagedShortcuts(NxtPackageConfigurationModel config)
		{
			return config.ManagedShortcuts?.Select(
				shortc =>
					new NxtShortcutOperation(
						shortc.Mode,
						shortc.Target,
						shortc.Location,
						shortc.Source
					)
			).ToList() ?? [];
		}

		private NxtInstallationInstructions GetInstallInstructions(NxtPackageConfigurationModel config)
		{
			var installModel = config.Deployment?.Installation ?? new NxtInstallationModel();
			var installObj = new NxtInstallationInstructions()
			{
				Method = installModel.Method,
				Target = installModel.Target ?? string.Empty,
				Arguments = installModel.Arguments ?? string.Empty,
				Defaults = installModel.Defaults,
				LogName = installModel.LogName ?? string.Empty,
				IgnoreExitCodes = installModel.IgnoreExitCodes,
				Reboot = installModel.Reboot,
				ReinstallMode = installModel.ReinstallMode,
				UpgradeMode = installModel.UpgradeMode,
				UserPart = installModel.UserPart
			};

			installModel.SuccessCodes?
				.Where(code => !installObj.SuccessCodes.Contains(code))
				.ToList()
				.ForEach(installObj.SuccessCodes.Add);

			installModel.RebootCodes?
				.Where(code => !installObj.RebootCodes.Contains(code))
				.ToList()
				.ForEach(installObj.RebootCodes.Add);

			var defaultTimeout = !string.IsNullOrWhiteSpace(installModel.Awaiters?.DefaultTimeout)
				? TimeSpan.Parse(installModel.Awaiters!.DefaultTimeout)
				: TimeSpan.FromSeconds(30);

			installModel.Awaiters?.RegistryKeys?.ForEach(key =>
				installObj.Awaiters.Add(
					new NxtRegistryAwaiter(
						key.Key,
						key.Name,
						key.Value,
						key.Exists,
						key.Timeout != null ? TimeSpan.Parse(key.Timeout) : defaultTimeout
					)
				)
			);
			installModel.Awaiters?.Processes?.ForEach(proc =>
				installObj.Awaiters.Add(
					new NxtProcessAwaiter(
						proc.Name,
						proc.Exists,
						proc.Timeout != null ? TimeSpan.Parse(proc.Timeout) : defaultTimeout
					)
				)
			);

			return installObj;
		}

		private NxtUninstallationInstructions GetUninstallInstructions(NxtPackageConfigurationModel config)
		{
			var uninstallModel = config.Deployment?.Uninstallation ?? new NxtUninstallationModel() { Method = Install.Method };
			var uninstallObj = new NxtUninstallationInstructions()
			{
				Method = uninstallModel.Method,
				Target = uninstallModel.Target ?? string.Empty,
				Arguments = uninstallModel.Arguments ?? string.Empty,
				Defaults = uninstallModel.Defaults,
				LogName = uninstallModel.LogName ?? string.Empty,
				IgnoreExitCodes = uninstallModel.IgnoreExitCodes,
				Reboot = uninstallModel.Reboot,
				UserPart = uninstallModel.UserPart
			};

			uninstallModel.SuccessCodes?
				.Where(code => !uninstallObj.SuccessCodes.Contains(code))
				.ToList()
				.ForEach(uninstallObj.SuccessCodes.Add);

			uninstallModel.RebootCodes?
				.Where(code => !uninstallObj.RebootCodes.Contains(code))
				.ToList()
				.ForEach(uninstallObj.RebootCodes.Add);

			var defaultTimeout = !string.IsNullOrWhiteSpace(uninstallModel.Awaiters?.DefaultTimeout)
				? TimeSpan.Parse(uninstallModel.Awaiters!.DefaultTimeout)
				: TimeSpan.FromSeconds(30);

			uninstallModel.Awaiters?.RegistryKeys?.ForEach(key =>
				uninstallObj.Awaiters.Add(
					new NxtRegistryAwaiter(
						key.Key,
						key.Name,
						key.Value,
						key.Exists,
						key.Timeout != null ? TimeSpan.Parse(key.Timeout) : defaultTimeout
					)
				)
			);
			uninstallModel.Awaiters?.Processes?.ForEach(proc =>
				uninstallObj.Awaiters.Add(
					new NxtProcessAwaiter(
						proc.Name,
						proc.Exists,
						proc.Timeout != null ? TimeSpan.Parse(proc.Timeout) : defaultTimeout
					)
				)
			);

			return uninstallObj;
		}

		public override string ToString()
		{
			return $"Neo42.Extensions for PSAppDeployToolkit v{GetType().Assembly.GetName().Version}";
		}

		private DirectoryInfo InitializePackageRootDirectory(string folderName, string keyName, NxtDeploymentType deploymentType)
		{
			using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
			using var packageRootKey = deploymentType.IsMachinePart
				? baseKey.CreateSubKey($"SOFTWARE\\{keyName}", true)
				: baseKey.OpenSubKey($"SOFTWARE\\{keyName}")
				?? throw new InvalidOperationException("Failed to access or create package root registry key. Administrative privileges may be required.");
			var programData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
			var knownNames = packageRootKey.GetValue("AppRootFolderNames") as string[] ?? [];
			var validNameRegex = new Regex($"^{Regex.Escape(folderName)}([0-9a-f]{8})?$", RegexOptions.Compiled | RegexOptions.IgnoreCase);
			var existingName = knownNames.FirstOrDefault(n => validNameRegex.IsMatch(n) && Directory.Exists(Path.Combine(programData, n)));

			if (!string.IsNullOrWhiteSpace(existingName))
			{
				return new DirectoryInfo(Path.Combine(programData, existingName));
			}

			if (!Process.GetCurrentProcess().IsElevated())
			{
				throw new InvalidOperationException("Package root directory does not exist and cannot be created without administrative privileges.");
			}

			var fullName = Path.Combine(programData, folderName);
			if (Directory.Exists(fullName))
			{
				_session.WriteLogEntry($"Package root directory name [{folderName}] exists, but is not managed by this package, generating a new unique name.", LogSeverity.Error);
				folderName = $"{folderName}{Guid.NewGuid().ToString("N").Substring(0, 8)}";
				if (Directory.Exists(Path.Combine(programData, folderName)))
				{
					throw new InvalidOperationException("Failed to generate a unique package root directory name.");
				}
				fullName = Path.Combine(programData, folderName);
			}

			var administrators = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
			var users = new SecurityIdentifier(WellKnownSidType.BuiltinUsersSid, null);
			var acl = new DirectorySecurity();
			acl.SetOwner(administrators);
			acl.AddAccessRule(new FileSystemAccessRule(
				administrators,
				FileSystemRights.FullControl,
				InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
				PropagationFlags.None,
				AccessControlType.Allow));
			acl.AddAccessRule(new FileSystemAccessRule(
				users,
				FileSystemRights.ReadAndExecute | FileSystemRights.ListDirectory,
				InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit,
				PropagationFlags.None,
				AccessControlType.Allow));

			_session.WriteLogEntry($"Creating package root directory [{fullName}].");

			var dir = NxtPath.CreateDirectory(fullName, acl);

			// Only register the new directory, when the method did not throw an exception, to avoid registering a directory that does not exist or is not accessible.
			packageRootKey.SetValue("AppRootFolderNames", knownNames.Concat([folderName]).Distinct().Where(n => Directory.Exists(Path.Combine(programData, n))).ToArray(), RegistryValueKind.MultiString);

			return dir;
		}

		private ScriptBlock GetUnboundScriptBlock(ScriptBlock scriptBlock)
		{
			return ((ScriptBlockAst)scriptBlock.Ast).GetScriptBlock();
		}
	}
}
