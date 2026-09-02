using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Text.RegularExpressions;
using PSADTNXT.Application;
using PSADTNXT.Package;
using PSADTNXT.Shell;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	internal static class NxtLegacyTranslations
	{
		internal static readonly Version MinimumLegacyConfigVersion = new(2024, 09, 19, 1);

		private static readonly IReadOnlyDictionary<string, string> _runtimeVariableMapping = new Dictionary<string, string>
		{
			{ "LogFolder", "%LogFolder%" },
			{ "DirFiles", "%DirFiles%" },
			{ "DirSupportFiles", "%DirSupportFiles%" },
			{ "PackageDirectory", "%PackageDirectory%" },
		};

		internal static void Expand(this NxtLegacyPackageConfigurationModel legacyModel, IDictionary<string, object> adtEnvironment, params SessionStateVariableEntry[] extraVariables)
		{
			var sessionStateVaraibles = NxtPowerShell.ToSessionStateVariables(adtEnvironment, NxtPowerShell.GLOBAL_CONSTANT_OPTION)
				.Concat(GetLegacyVariables(adtEnvironment, legacyModel.AppArch))
				.Concat(extraVariables)
				.Append(new SessionStateVariableEntry("PackageConfig", legacyModel, "", NxtPowerShell.GLOBAL_CONSTANT_OPTION));

			using var ps = PowerShell.Create(NxtPowerShell.GetExpansionSessionState(sessionStateVaraibles));

			static string ReplaceRuntimeVariables(string legacyModel)
			{
				foreach (var variable in _runtimeVariableMapping)
				{
					legacyModel = Regex.Replace(legacyModel, @"\$(?:(?:global|script|local)\:)?" + Regex.Escape(variable.Key) + @"\b", variable.Value, RegexOptions.IgnoreCase);
				}
				return legacyModel;
			}

			// Set obsolet values to placeholders so self-referencing variables do not cause issues
#pragma warning disable CS0618
			legacyModel.App = "%PackageDirectory%";
#pragma warning restore CS0618

			// Expand all other strings based on V3 logic
			legacyModel.UninstallDisplayName = ps.ExpandString(legacyModel.UninstallDisplayName);
			legacyModel.InstallLocation = ps.ExpandString(legacyModel.InstallLocation);
			legacyModel.InstLogFile = ps.ExpandString(legacyModel.InstLogFile);
			legacyModel.UninstLogFile = ps.ExpandString(legacyModel.UninstLogFile);
			legacyModel.InstFile = ps.ExpandString(ReplaceRuntimeVariables(legacyModel.InstFile));
			legacyModel.InstPara = ps.ExpandString(ReplaceRuntimeVariables(legacyModel.InstPara));
			legacyModel.UninstFile = ps.ExpandString(ReplaceRuntimeVariables(legacyModel.UninstFile));
			legacyModel.UninstPara = ps.ExpandString(ReplaceRuntimeVariables(legacyModel.UninstPara));

			if (legacyModel.UninstallKeyContainsExpandVariables)
			{
				legacyModel.UninstallKey = ps.ExpandString(legacyModel.UninstallKey);
			}

			legacyModel.DisplayNamesToExcludeFromAppSearches = legacyModel.DisplayNamesToExcludeFromAppSearches?.Select(ps.ExpandString).ToList();

			if (legacyModel.UninstallKeysToHide is List<NxtLegacyKeyHideModel> hideKeys)
			{
				foreach (var hideKey in hideKeys)
				{
					hideKey.KeyName = ps.ExpandString(hideKey.KeyName);
					hideKey.KeyNameIsDisplayName = ps.ExpandString(hideKey.KeyNameIsDisplayName);
					hideKey.KeyNameContainsWildCards = ps.ExpandString(hideKey.KeyNameContainsWildCards);
					hideKey.DisplayNamesToExcludeFromHiding = hideKey.DisplayNamesToExcludeFromHiding?.Select(ps.ExpandString).ToList();
				}
			}

			legacyModel.CommonDesktopShortcutsToDelete = legacyModel.CommonDesktopShortcutsToDelete?.Select(ps.ExpandString).ToList();
			if (legacyModel.CommonStartMenuShortcutsToCopyToCommonDesktop is List<NxtLegacyShortcutCopyModel> shortcutCopies)
			{
				foreach (var shortcutCopy in shortcutCopies)
				{
					shortcutCopy.Source = ps.ExpandString(shortcutCopy.Source);
					shortcutCopy.TargetName = ps.ExpandString(shortcutCopy.TargetName);
				}
			}

			if (legacyModel.SoftMigration?.File is NxtLegacySoftMigrationFileModel softMigrationFile)
			{
				softMigrationFile.FullNameToCheck = ps.ExpandString(softMigrationFile.FullNameToCheck);
				softMigrationFile.VersionToCheck = ps.ExpandString(softMigrationFile.VersionToCheck);
			}

			if (legacyModel.PackageSpecificVariablesRaw is List<NxtLegacyVariableModel> packageSpecificVariables)
			{
				foreach (var variable in packageSpecificVariables)
				{
					if (variable.ExpandVariables)
					{
						variable.Value = ps.ExpandString(ReplaceRuntimeVariables(variable.Value));
					}
				}
			}
		}

		internal static NxtPackageConfigurationModel Translate(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtPackageConfigurationModel
			{
				ConfigVersion = new Version(2025, 12, 1, 0),
				Package = legacyModel.TranslatePackageMetadataModel(),
				Requirements = legacyModel.TranslateRequirementModels(),
				Detection = legacyModel.TranslateDetectionModel(),
				SoftMigration = legacyModel.TranslateSoftmigrationModel(),
				CloseProcesses = legacyModel.TranslateCloseProcessModels(),
				ManagedShortcuts = legacyModel.TranslateManagedShortcutModels(),
				ManagedApplications = legacyModel.TranslateManagedApplicationModels(),
				Deployment = legacyModel.TranslateDeploymentContainerModel(),
				Variables = legacyModel.TranslateVariables()
			};
		}

		internal static DeploymentMethod? MapLegacyDeploymentMethodToEnum(string method)
		{
			return method.Equals("None", StringComparison.OrdinalIgnoreCase)
				? null
				: method.StartsWith("BitRock", StringComparison.OrdinalIgnoreCase)
				? DeploymentMethod.BitRockInstaller
				: method.StartsWith("Inno", StringComparison.OrdinalIgnoreCase)
				? DeploymentMethod.InnoSetup
				: Enum.TryParse<DeploymentMethod>(method, true, out var deploymentMethod)
				? deploymentMethod
				: DeploymentMethod.Setup;
		}

		internal static NxtPackageMetadataModel TranslatePackageMetadataModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtPackageMetadataModel
			{
				GUID = legacyModel.PackageGUID,
				Vendor = legacyModel.AppVendor,
				Name = legacyModel.AppName,
				Version = legacyModel.AppVersion,
				Architecture = Enum.TryParse<PackageArchitecture>(legacyModel.AppArch, true, out var arch) ? arch : PackageArchitecture.neutral,
				Language = !string.IsNullOrWhiteSpace(legacyModel.AppLang) ? legacyModel.AppLang : "MUI",
				DisplayName = !legacyModel.UninstallDisplayName.EndsWith(legacyModel.AppVersion) ? legacyModel.UninstallDisplayName : legacyModel.UninstallDisplayName.Substring(0, legacyModel.UninstallDisplayName.Length - legacyModel.AppVersion.Length).TrimEnd(),
				Description = legacyModel.Description,
				Author = legacyModel.ScriptAuthor,
				Revision = uint.Parse(legacyModel.AppRevision),
				Build = uint.Parse(legacyModel.Build),
				UpdateDate = DateTime.ParseExact(legacyModel.LastChange, "dd/MM/yyyy", null).ToString("yyyy-MM-dd"),
				CreationDate = DateTime.ParseExact(legacyModel.ScriptDate, "dd/MM/yyyy", null).ToString("yyyy-MM-dd"),
				TestedOn = legacyModel.TestedOn,
				InventoryId = legacyModel.InventoryID,
				Dependencies = legacyModel.Dependencies,
				KeyName = legacyModel.RegPackagesKey,
				DirectoryName = legacyModel.AppRootFolder,
				UninstallOld = legacyModel.UninstallOld,
				ApplicationEntry = legacyModel.HidePackageUninstallEntry ? ArpRegistrationType.Hidden : legacyModel.HidePackageUninstallButton ? ArpRegistrationType.DisplayOnly : ArpRegistrationType.Uninstallable
			};
		}

		internal static List<NxtRequirementModel> TranslateRequirementModels(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return legacyModel.DependentPackages?
				.Select(d => new NxtRequirementModel()
				{
					Criteria = new NxtApplicationCriteriaModel()
					{
						Store = ApplicationStore.Package,
						Identifier = d.GUID
					},
					DesiredState = Enum.TryParse<RequirementState>(d.DesiredState, true, out var dState) ? dState : throw new InvalidDataException($"Desired state '{d.DesiredState}' could not be parsed."),
					OnConflict = Enum.TryParse<RequirementConflictAction>(d.OnConflict, true, out var onConflict) ? onConflict : throw new InvalidDataException($"Conflict action '{d.OnConflict}' could not be parsed."),
					ErrorMessage = !string.IsNullOrWhiteSpace(d.ErrorMessage) ? d.ErrorMessage : null
				})
				.ToList() ?? [];
		}

		internal static NxtApplicationDetectionModel TranslateDetectionModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var detectionModel = new NxtApplicationDetectionModel()
			{
				Enabled = false,
				Version = !string.IsNullOrWhiteSpace(legacyModel.DisplayVersion) ? legacyModel.DisplayVersion : null,
			};

			if (!string.IsNullOrWhiteSpace(legacyModel.UninstallKey))
			{
				detectionModel.Enabled = true;
				detectionModel.Criteria = new NxtApplicationCriteriaModel
				{
					Store = ApplicationStore.ARP,
					Identifier = !legacyModel.UninstallKeyIsDisplayName && !legacyModel.UninstallKeyContainsWildCards ? legacyModel.UninstallKey : null,
				};
				var detectionScript = new StringBuilder();
				if (legacyModel.UninstallKeyIsDisplayName)
				{
					_ = detectionScript.Append("$_.DisplayName");
					_ = detectionScript.Append(legacyModel.UninstallKeyContainsWildCards ? " -like " : " -eq ");
					_ = detectionScript.Append($"'{legacyModel.UninstallKey.Replace("'", "''")}'");
				}
				else if (legacyModel.UninstallKeyContainsWildCards)
				{
					_ = detectionScript.Append($"$_.PSChildName -like '{legacyModel.UninstallKey.Replace("'", "''")}'");
				}
				if (legacyModel.DisplayNamesToExcludeFromAppSearches is List<string> displayNamesToExclude && displayNamesToExclude.Count != 0)
				{
					if (detectionScript.Length > 0)
					{
						_ = detectionScript.Append(" -and ");
					}
					_ = detectionScript.Append("$_.DisplayName -notin @(");
					_ = detectionScript.Append(string.Join(", ", displayNamesToExclude.Select(name => $"'{name.Replace("'", "''")}'")));
					_ = detectionScript.Append(')');
				}
				detectionModel.Criteria.Filter = ScriptBlock.Create(detectionScript.ToString());
			}

			return detectionModel;
		}

		internal static NxtSoftMigrationModel TranslateSoftmigrationModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var softMigrationModel = new NxtSoftMigrationModel()
			{
				Enabled = false,
			};
			if (!string.IsNullOrWhiteSpace(legacyModel.SoftMigration?.File?.FullNameToCheck))
			{
				softMigrationModel.Enabled = true;
				softMigrationModel.Mode = SoftMigrationDetectionMode.File;
				softMigrationModel.Target = legacyModel.SoftMigration!.File!.FullNameToCheck;
				softMigrationModel.Version = legacyModel.SoftMigration.File?.VersionToCheck;
			}
			else if (!string.IsNullOrWhiteSpace(legacyModel.DisplayVersion) && !string.IsNullOrWhiteSpace(legacyModel.UninstallKey))
			{
				softMigrationModel.Enabled = true;
				softMigrationModel.Mode = SoftMigrationDetectionMode.Detection;
				softMigrationModel.Version = legacyModel.DisplayVersion;
			}

			return softMigrationModel;
		}

		internal static List<NxtCloseProcessesModel> TranslateCloseProcessModels(this NxtLegacyPackageConfigurationModel legacyModel)
		{
#pragma warning disable CS0618
			return legacyModel.AppKillProcesses?
				.Select(p => p.IsWql
					? throw new NotSupportedException("WQL process detection is not supported in the new package configuration format.")
					: new NxtCloseProcessesModel()
					{
						Name = p.Name,
						Description = p.Description,
						AllowBlocking = !legacyModel.BlockExecution
					}
				)
				.ToList() ?? [];
#pragma warning restore CS0618
		}

		internal static List<NxtShortcutModel> TranslateManagedShortcutModels(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var managedShortcuts = new List<NxtShortcutModel>();
			managedShortcuts.AddRange(
				legacyModel.CommonStartMenuShortcutsToCopyToCommonDesktop?.Select(s => new NxtShortcutModel()
				{
					Mode = ShortcutOperation.Copy,
					Location = ShortcutLocation.Desktop,
					Target = s.TargetName,
					Source = s.Source
				}) ?? []
			);
			managedShortcuts.AddRange(
				legacyModel.CommonDesktopShortcutsToDelete?
					.Where(s => !managedShortcuts.Any(c => c.Target == s))
					.Select(s => new NxtShortcutModel()
					{
						Mode = ShortcutOperation.Delete,
						Location = ShortcutLocation.Desktop,
						Target = s
					}) ?? []
			);

			return managedShortcuts;
		}

		internal static List<NxtApplicationCriteriaModel> TranslateManagedApplicationModels(this NxtLegacyPackageConfigurationModel legacyModel)
		{

			var managedApplications = new List<NxtApplicationCriteriaModel>();
			if (legacyModel.UninstallKeysToHide is List<NxtLegacyKeyHideModel> uninstallKeysToHide)
			{
				foreach (var keyToHide in uninstallKeysToHide)
				{
					var isDisplayName = bool.TryParse(keyToHide.KeyNameIsDisplayName, out var keyIsDisplayName) && keyIsDisplayName;
					var containsWildCards = bool.TryParse(keyToHide.KeyNameContainsWildCards, out var keyContainsWildCards) && keyContainsWildCards;

					var criteria = new NxtApplicationCriteriaModel()
					{
						Store = ApplicationStore.ARP,
					};
					if (!isDisplayName && !containsWildCards)
					{
						criteria.Identifier = keyToHide.KeyName;
					}
					else
					{
						criteria.Filter = ScriptBlock.Create(
							(isDisplayName ? "$_.DisplayName" : "$_.ProductCode") +
							(containsWildCards ? " -like " : " -eq ") +
							$"'{keyToHide.KeyName}'"
						);
					}
				}
			}
			return managedApplications;
		}

		internal static NxtDeploymentContainerModel TranslateDeploymentContainerModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtDeploymentContainerModel
			{
				InstallLocation = legacyModel.InstallLocation,
				Installation = legacyModel.TranslateInstallationModel(),
				Uninstallation = legacyModel.TranslateUninstallationModel()
			};
		}

		internal static NxtInstallationModel TranslateInstallationModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtInstallationModel
			{
				Method = MapLegacyDeploymentMethodToEnum(legacyModel.InstallMethod),
				Target = legacyModel.InstFile,
				Arguments = legacyModel.InstPara,
				Defaults = legacyModel.AppendInstParaToDefaultParameters || string.IsNullOrWhiteSpace(legacyModel.InstPara),
				LogName = Path.GetFileName(legacyModel.InstLogFile),
				SuccessCodes = string.IsNullOrWhiteSpace(legacyModel.AcceptedInstallExitCodes) ? [0] : [.. legacyModel.AcceptedInstallExitCodes.Replace("*", "").Split([','], StringSplitOptions.RemoveEmptyEntries).Select(s => int.Parse(s.Trim()))],
				RebootCodes = string.IsNullOrWhiteSpace(legacyModel.AcceptedInstallRebootCodes) ? [1641, 3010] : [.. legacyModel.AcceptedInstallRebootCodes.Split([','], StringSplitOptions.RemoveEmptyEntries).Select(s => int.Parse(s.Trim()))],
				IgnoreExitCodes = legacyModel.AcceptedInstallExitCodes?.Contains("*") ?? false,
				Reboot = (RebootAction)legacyModel.Reboot,
				ReinstallMode = Enum.TryParse<ReinstallMode>(legacyModel.ReinstallMode.Replace("MSIRepair", "Repair"), true, out var reinstallMode) ? reinstallMode : throw new InvalidDataException($"Reinstall mode '{legacyModel.ReinstallMode}' could not be parsed."),
				UpgradeMode = legacyModel.ReinstallMode.Equals("MSIRepair", StringComparison.OrdinalIgnoreCase)
					? legacyModel.MSIInplaceUpgradeable
						? UpgradeMode.Install
						: UpgradeMode.Reinstall
					: Enum.TryParse<UpgradeMode>(legacyModel.ReinstallMode, true, out var upgradeMode)
						? upgradeMode
						: throw new InvalidDataException($"Upgrade mode '{legacyModel.ReinstallMode}' could not be parsed."),
				Awaiters = new NxtAwaiterModel
				{
					DefaultTimeout = TimeSpan.FromSeconds(legacyModel.TestConditionsPreSetupSuccessCheck?.Install?.TotalSecondsToWaitFor ?? 30).ToString(),
					RegistryKeys = legacyModel.TestConditionsPreSetupSuccessCheck?.Install?.RegKeysToWaitFor is List<NxtLegacyRegistryConditionModel> installAwaiterRegKeys
						? [.. installAwaiterRegKeys.Select(r =>
									new NxtRegistryAwaiterModel
									{
										Key = r.KeyPath,
										Name = r.ValueName ?? string.Empty,
										Value = r.ValueData ?? string.Empty,
										Exists = r.ShouldExist
									}
								)]
						: [],
					Processes = legacyModel.TestConditionsPreSetupSuccessCheck?.Install?.ProcessesToWaitFor is List<NxtLegacyProcessConditionModel> installAwaiterProcesses
						? [.. installAwaiterProcesses.Select(p =>
									new NxtProcessAwaiterModel
									{
										Name = p.Name,
										Exists = p.ShouldExist
									}
								)]
						: []
				},
				UserPart = legacyModel.UserPartOnInstallation,
			};

		}

		internal static NxtUninstallationModel TranslateUninstallationModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtUninstallationModel
			{
				Method = MapLegacyDeploymentMethodToEnum(legacyModel.UninstallMethod),
				Target = legacyModel.UninstFile,
				Arguments = legacyModel.UninstPara,
				Defaults = legacyModel.AppendUninstParaToDefaultParameters || string.IsNullOrWhiteSpace(legacyModel.UninstPara),
				LogName = Path.GetFileName(legacyModel.UninstLogFile),
				SuccessCodes = string.IsNullOrWhiteSpace(legacyModel.AcceptedUninstallExitCodes)
						? [0]
						: [.. legacyModel.AcceptedUninstallExitCodes.Replace("*", "").Split([','], StringSplitOptions.RemoveEmptyEntries).Select(s => int.Parse(s.Trim()))],
				RebootCodes = string.IsNullOrWhiteSpace(legacyModel.AcceptedUninstallRebootCodes)
						? [1641, 3010]
						: [.. legacyModel.AcceptedUninstallRebootCodes.Split([','], StringSplitOptions.RemoveEmptyEntries).Select(s => int.Parse(s.Trim()))],
				IgnoreExitCodes = legacyModel.AcceptedUninstallExitCodes?.Contains("*") ?? false,
				Reboot = (RebootAction)legacyModel.Reboot,
				Awaiters = new NxtAwaiterModel
				{
					DefaultTimeout = TimeSpan.FromSeconds(legacyModel.TestConditionsPreSetupSuccessCheck?.Uninstall?.TotalSecondsToWaitFor ?? 30).ToString(),
					RegistryKeys = legacyModel.TestConditionsPreSetupSuccessCheck?.Uninstall?.RegKeysToWaitFor is List<NxtLegacyRegistryConditionModel> uninstallAwaiterRegKeys
							? [.. uninstallAwaiterRegKeys.Select(r =>
								new NxtRegistryAwaiterModel
								{
									Key = r.KeyPath,
									Name = r.ValueName ?? string.Empty,
									Value = r.ValueData ?? string.Empty,
									Exists = r.ShouldExist
								}
							)]
							: [],
					Processes = legacyModel.TestConditionsPreSetupSuccessCheck?.Uninstall?.ProcessesToWaitFor is List<NxtLegacyProcessConditionModel> uninstallAwaiterProcesses
							? [.. uninstallAwaiterProcesses.Select(p =>
								new NxtProcessAwaiterModel
								{
									Name = p.Name,
									Exists = p.ShouldExist
								}
							)]
							: []
				},
				UserPart = legacyModel.UserPartOnUninstallation,

			};

		}

		internal static Dictionary<string, object> TranslateVariables(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var variables = new Dictionary<string, object>();
			if (legacyModel.PackageSpecificVariablesRaw is List<NxtLegacyVariableModel> packageSpecificVariables)
			{
				packageSpecificVariables.ForEach(v => variables[v.Name] = v.Value);
			}

#pragma warning disable CS0618
			variables["Legacy_ConfigVersion"] = legacyModel.ConfigVersion;
			variables["Legacy_InventoryID"] = legacyModel.InventoryID;
			variables["Legacy_Description"] = legacyModel.Description;
			variables["Legacy_TestedOn"] = legacyModel.TestedOn;
			variables["Legacy_Dependencies"] = legacyModel.Dependencies;
			variables["Legacy_ProductGUID"] = legacyModel.ProductGUID;
			variables["Legacy_RemovePackagesWithSameProductGUID"] = legacyModel.RemovePackagesWithSameProductGUID;
			variables["Legacy_HidePackageUninstallButton"] = legacyModel.HidePackageUninstallButton;
			variables["Legacy_HidePackageUninstallEntry"] = legacyModel.HidePackageUninstallEntry;
			variables["Legacy_InstallerVersion"] = legacyModel.InstallerVersion;
			variables["Legacy_UninstallKey"] = legacyModel.UninstallKey;
			variables["Legacy_UninstallKeyIsDisplayName"] = legacyModel.UninstallKeyIsDisplayName;
			variables["Legacy_UninstallKeyContainsWildCards"] = legacyModel.UninstallKeyContainsWildCards;
			variables["Legacy_UninstallKeyContainsExpandVariables"] = legacyModel.UninstallKeyContainsExpandVariables;
			variables["Legacy_DisplayNamesToExcludeFromAppSearches"] = legacyModel.DisplayNamesToExcludeFromAppSearches ?? [];
#pragma warning restore CS0618

			return variables;
		}

		private static List<SessionStateVariableEntry> GetLegacyVariables(IDictionary<string, object> adtEnvironment, string arch)
		{
			var result = new List<SessionStateVariableEntry>();

			// Arch specific variables
			if (arch.Equals("x86", StringComparison.OrdinalIgnoreCase) || arch.Equals("arm", StringComparison.OrdinalIgnoreCase))
			{
				result.Add(new SessionStateVariableEntry("ProgramFilesDir", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("ProgramFilesDirx86", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("ProgramW6432", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonFilesDir", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonFilesDirx86", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonProgramW6432", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("RegSoftwarePath", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("RegSoftwarePathx86", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("System", adtEnvironment["envSystemX86"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			}
			else
			{
				result.Add(new SessionStateVariableEntry("ProgramFilesDir", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("ProgramFilesDirx86", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("ProgramW6432", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonFilesDir", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonFilesDirx86", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("CommonProgramW6432", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("RegSoftwarePath", adtEnvironment["envRegistrySoftware"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("RegSoftwarePathx86", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new SessionStateVariableEntry("System", adtEnvironment["envSystemX64"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			}

			result.Add(new SessionStateVariableEntry("UserPartDir", string.Empty, string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			result.Add(new SessionStateVariableEntry("AppLogFolder", "%LogFolder%", string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));

			return result;
		}
	}
}
