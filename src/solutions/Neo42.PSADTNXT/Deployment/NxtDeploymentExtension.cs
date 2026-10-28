using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
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
		public SessionState? DeployAppScriptSessionState { get; }

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

		[Hidden]
		public string? ErrorMessage { get; set; }

		[Hidden]
		public string? ErrorPhase { get; set; }

		[Hidden]
		public DeploymentHookPoint? LastRunHookPoint { get; set; }

		[Hidden]
		public bool DeploymentInvoked { get; set; }

		[Hidden]
		[Obsolete("Feature is implemented in 4.2.0")]
		public bool ExitWithMsiCodes { get; set; }

		[Hidden]
		public bool IsCached { get; set; }

		public NxtIniDocument SetupCfg { get; }

		public Dictionary<string, object> Variables { get; }

		public NxtDeploymentExtension(NxtDeploymentSession session, IReadOnlyDictionary<string, object> parameters)
		{
			_session = session ?? throw new ArgumentNullException(nameof(session));

			if (string.IsNullOrWhiteSpace(_session.AppVendor) || string.IsNullOrWhiteSpace(_session.AppName))
			{
				throw new InvalidDataException("AppVendor and AppName are required parameters for neo42 session construction.");
			}

			SetupCfg = TryGetParameterValue<NxtIniDocument>(parameters, "SetupCfg", out var setupCfg) ? setupCfg! : throw new ArgumentException("SetupCfg parameter is required and must be of type NxtIniDocument.");
			DeploymentType = TryGetParameterValue<NxtDeploymentType>(parameters, "NxtDeploymentType", out var nxtDeploymentType) ? nxtDeploymentType! : _session.DeploymentType;
			DeploymentSystem = TryGetParameterValue<string>(parameters, "DeploymentSystem", out var deploymentSystem) ? deploymentSystem! : "Unknown";
			DeployAppScript = TryGetParameterValue<string>(parameters, "DeployAppScriptPath", out var scriptPath) ? new(scriptPath!) : throw new ArgumentException("DeployAppScriptPath parameter is required.");
#pragma warning disable CS0618
			DeployAppScriptSessionState = TryGetParameterValue<SessionState>(parameters, "DeployAppScriptSessionState", out var sessionState) ? sessionState! : throw new ArgumentException("DeployAppScriptSessionState parameter is required.");
			ExitWithMsiCodes = TryGetParameterValue<SwitchParameter>(parameters, "ExitWithMsiCodes", out var exitWithMsiCodesSwitch) && exitWithMsiCodesSwitch!.ToBool();
#pragma warning restore CS0618

			if (!TryGetParameterValue<NxtPackageConfigurationModel>(parameters, "PackageConfig", out var packageConfig))
			{
				throw new ArgumentException("PackageConfig parameter is required and must be of type NxtPackageConfigurationModel.");
			}

			var nxtConfig = ModuleDatabase.GetConfig()["NXT"] as Hashtable;
			var nxtToolkitConfig = nxtConfig?["Toolkit"] as Hashtable;
			var appendVersion = nxtToolkitConfig?["AppendVersionToPackageName"] is bool append && append;

			var packageRootDir = InitializePackageRootDirectory(packageConfig!.Package.DirectoryName, packageConfig.Package.KeyName);
			_session.WriteLogEntry($"Package cache directory resides in [{packageRootDir.FullName}].");

			Package = GetPackageMetadata(packageConfig, packageRootDir, appendVersion);
			Requirements = GetPackageRequirements(packageConfig);
			Detection = GetInstallDetection(packageConfig);
			SoftMigration = GetSoftMigration(packageConfig);
			CloseProcesses = GetCloseProcesses(packageConfig);
			ManagedShortcuts = GetManagedShortcuts(packageConfig);
			ManagedApplications = packageConfig.ManagedApplications?.Select(ConvertToCriteria).ToList() ?? [];
			UserPartRevision = packageConfig.Package.Version.Replace(".", ",") + string.Concat(Enumerable.Repeat(",0", 3 - packageConfig.Package.Version.Count(c => c == '.')));
			InstallLocation = !string.IsNullOrWhiteSpace(packageConfig.Deployment?.InstallLocation) ? new(packageConfig.Deployment!.InstallLocation) : null;
			Install = GetInstallInstructions(packageConfig);
			Uninstall = GetUninstallInstructions(packageConfig);
			Variables = new(packageConfig.Variables ?? [], StringComparer.OrdinalIgnoreCase);

			Install.Target = ExpandRuntimeVariable(Install.Target);
			Install.Arguments = ExpandRuntimeVariable(Install.Arguments);
			Uninstall.Target = ExpandRuntimeVariable(Uninstall.Target);
			Uninstall.Arguments = ExpandRuntimeVariable(Uninstall.Arguments);
			ExpandRuntimeVariablesInObject(Variables);
		}

		private static bool TryGetParameterValue<T>(IReadOnlyDictionary<string, object> parameters, string parameterName, out T? parameterValue)
		{
			if (parameters.TryGetValue(parameterName, out var objValue) && objValue is T typedValue)
			{
				parameterValue = typedValue;
				return true;

			}
			parameterValue = default;
			return false;
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
				Hide = config.Detection?.Hide ?? true,
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
				AwaitChildren = installModel.AwaitChildren,
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
				? installModel.Awaiters!.DefaultTimeout.ParseTimeSpan()
				: TimeSpan.FromSeconds(30);

			installModel.Awaiters?.RegistryKeys?.ForEach(key =>
				installObj.Awaiters.Add(
					new NxtRegistryAwaiter(
						key.Key,
						key.Name,
						key.Value,
						key.Exists,
						key.Timeout != null ? key.Timeout.ParseTimeSpan() : defaultTimeout
					)
				)
			);
			installModel.Awaiters?.Processes?.ForEach(proc =>
				installObj.Awaiters.Add(
					new NxtProcessAwaiter(
						proc.Name,
						proc.Exists,
						proc.Timeout != null ? proc.Timeout.ParseTimeSpan() : defaultTimeout
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
				AwaitChildren = uninstallModel.AwaitChildren,
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
				? uninstallModel.Awaiters!.DefaultTimeout.ParseTimeSpan()
				: TimeSpan.FromSeconds(30);

			uninstallModel.Awaiters?.RegistryKeys?.ForEach(key =>
				uninstallObj.Awaiters.Add(
					new NxtRegistryAwaiter(
						key.Key,
						key.Name,
						key.Value,
						key.Exists,
						key.Timeout != null ? key.Timeout.ParseTimeSpan() : defaultTimeout
					)
				)
			);
			uninstallModel.Awaiters?.Processes?.ForEach(proc =>
				uninstallObj.Awaiters.Add(
					new NxtProcessAwaiter(
						proc.Name,
						proc.Exists,
						proc.Timeout != null ? proc.Timeout.ParseTimeSpan() : defaultTimeout
					)
				)
			);

			return uninstallObj;
		}

		public override string ToString()
		{
			return $"Neo42.Extensions for PSAppDeployToolkit v{GetType().Assembly.GetName().Version}";
		}

		private DirectoryInfo InitializePackageRootDirectory(string folderName, string keyName)
		{
			using var baseKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
			using var packageRootKey = baseKey.OpenSubKey($"SOFTWARE\\{keyName}") ?? baseKey.CreateSubKey($"SOFTWARE\\{keyName}");
			var programData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
			var knownNames = packageRootKey.GetValue("AppRootFolderNames") as string[] ?? [];
			var validNameRegex = new Regex($"^{Regex.Escape(folderName)}([0-9a-f]{{8}})?$", RegexOptions.Compiled | RegexOptions.IgnoreCase);
			var existingName = knownNames.FirstOrDefault(n => validNameRegex.IsMatch(n) && Directory.Exists(Path.Combine(programData, n)));

			if (!string.IsNullOrWhiteSpace(existingName))
			{
				return new DirectoryInfo(Path.Combine(programData, existingName));
			}

			var fullName = Path.Combine(programData, folderName);
			if (Directory.Exists(fullName))
			{
				_session.WriteLogEntry($"Package root directory name [{folderName}] exists, but was not found in [{packageRootKey.Name}] store. Generating new one.", LogSeverity.Error);
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
			using var packageRootKeyWriteable = baseKey.OpenSubKey($"SOFTWARE\\{keyName}", true)!;
			packageRootKeyWriteable.SetValue("AppRootFolderNames", knownNames.Concat([folderName]).Distinct().Where(n => Directory.Exists(Path.Combine(programData, n))).ToArray(), RegistryValueKind.MultiString);

			return dir;
		}

		private ScriptBlock GetUnboundScriptBlock(ScriptBlock scriptBlock)
		{
			return ((ScriptBlockAst)scriptBlock.Ast).GetScriptBlock();
		}

		private string ExpandRuntimeVariable(string text)
		{
			static string Replace(string input, string variable, string value)
			{
				var token = $"%{variable}%";
				var index = input.IndexOf(token, StringComparison.OrdinalIgnoreCase);
				while (index >= 0)
				{
					input = input.Remove(index, token.Length).Insert(index, value);
					index = input.IndexOf(token, index + value.Length, StringComparison.OrdinalIgnoreCase);
				}
				return input;
			}

			text = Replace(text, "LogFolder", _session.LogPath);
			text = Replace(text, "InstLogFile", Path.Combine(_session.LogPath, Install.LogName));
			text = Replace(text, "UninstLogFile", Path.Combine(_session.LogPath, Uninstall.LogName));
			text = Replace(text, "DirFiles", _session.DirFiles ?? string.Empty);
			text = Replace(text, "DirSupportFiles", _session.DirSupportFiles ?? string.Empty);
			text = Replace(text, "PackageDirectory", Package.Directory.FullName);
			text = Replace(text, "InstallLocation", InstallLocation?.FullName ?? string.Empty);

			return text;
		}

		private void ExpandRuntimeVariablesInObject(object? input)
		{
#pragma warning disable IDE0078
			if (input is IDictionary dict)
			{
				// Snapshot the keys, on .NET Framework assigning through the indexer invalidates the key enumerator.
				foreach (var key in dict.Keys.Cast<object>().ToList())
				{
					if (dict[key] is string dictString)
					{
						dict[key] = ExpandRuntimeVariable(dictString);
					}
					else
					{
						ExpandRuntimeVariablesInObject(dict[key]);
					}
				}
			}
			else if (input is IList list)
			{
				for (var i = 0; i < list.Count; i++)
				{
					if (list[i] is string listString)
					{
						list[i] = ExpandRuntimeVariable(listString);
					}
					else
					{
						ExpandRuntimeVariablesInObject(list[i]);
					}
				}
			}
#pragma warning restore IDE0078
			return;
		}
	}
}
