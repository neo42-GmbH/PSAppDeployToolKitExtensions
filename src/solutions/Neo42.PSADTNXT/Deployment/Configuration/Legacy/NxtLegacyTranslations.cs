using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using PSADTNXT.Application;
using PSADTNXT.Package;
using PSADTNXT.ProcessManagement;
using PSADTNXT.Shell;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	internal static class NxtLegacyTranslations
	{
		internal static readonly Version MinimumLegacyConfigVersion = new(2024, 09, 19, 1);

		internal static void Expand(this NxtLegacyPackageConfigurationModel legacyModel, IDictionary<string, object> adtEnvironment, params SessionStateVariableEntry[] extraVariables)
		{
			var sessionStateVariables = NxtPowerShell.ToSessionStateVariables(adtEnvironment, NxtPowerShell.GLOBAL_CONSTANT_OPTION)
				.Concat(GetLegacyVariables(adtEnvironment, legacyModel))
				.Concat(extraVariables);

			using var ps = PowerShell.Create(NxtPowerShell.GetExpansionSessionState(sessionStateVariables));

			// Set obsolet values to placeholders so self-referencing variables do not cause issues
#pragma warning disable CS0618
			legacyModel.App = "%PackageDirectory%";
#pragma warning restore CS0618

			// Expand all other strings based on V3 logic
			legacyModel.UninstallDisplayName = ps.ExpandString(legacyModel.UninstallDisplayName);
			legacyModel.InstallLocation = ps.ExpandString(legacyModel.InstallLocation);
			legacyModel.InstLogFile = ps.ExpandString(legacyModel.InstLogFile);
			legacyModel.UninstLogFile = ps.ExpandString(legacyModel.UninstLogFile);
			legacyModel.InstFile = ps.ExpandString(legacyModel.InstFile);
			legacyModel.InstPara = ps.ExpandString(legacyModel.InstPara);
			legacyModel.UninstFile = ps.ExpandString(legacyModel.UninstFile);
			legacyModel.UninstPara = ps.ExpandString(legacyModel.UninstPara);

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
				// Default reference to UninstallKey may result in empty, which will not pass validation. Remove it as it serves no purpose
				_ = hideKeys.RemoveAll(k => string.IsNullOrWhiteSpace(k.KeyName));
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
						variable.Value = ps.ExpandString(variable.Value);
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

		private static DeploymentMethod? MapLegacyDeploymentMethodToEnum(string method)
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

		private static NxtPackageMetadataModel TranslatePackageMetadataModel(this NxtLegacyPackageConfigurationModel legacyModel)
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

		private static List<NxtRequirementModel> TranslateRequirementModels(this NxtLegacyPackageConfigurationModel legacyModel)
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

		private static NxtApplicationDetectionModel TranslateDetectionModel(this NxtLegacyPackageConfigurationModel legacyModel)
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
				};

				var detectionScript = new StringBuilder();
				if (!legacyModel.UninstallKeyIsDisplayName && !legacyModel.UninstallKeyContainsWildCards)
				{
					detectionModel.Criteria.Identifier = legacyModel.UninstallKey;
				}
				else
				{
					if (legacyModel.UninstallKeyIsDisplayName)
					{
						_ = detectionScript.Append("$_.DisplayName");
						_ = detectionScript.Append(legacyModel.UninstallKeyContainsWildCards ? " -like " : " -eq ");
						_ = detectionScript.Append($"'{legacyModel.UninstallKey.Replace("'", "''")}'");
					}
					else
					{
						_ = detectionScript.Append($"$_.PSChildName -like '{legacyModel.UninstallKey.Replace("'", "''")}'");
					}
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

				if (detectionScript.Length > 0)
				{
					detectionModel.Criteria.Filter = ScriptBlock.Create(detectionScript.ToString());
				}
			}

			if (legacyModel.TryGetCompatVariable("DetectionCriteriaStore", out var detectionStoreVar))
			{
				detectionModel.Enabled = true;
				detectionModel.Criteria ??= new NxtApplicationCriteriaModel();
				detectionModel.Criteria.Store = Enum.TryParse<ApplicationStore>(detectionStoreVar, true, out var varStore)
					? varStore
					: throw new InvalidDataException($"The value [{detectionStoreVar}] of [DetectionCriteriaStore] cannot be parsed into an [ApplicationStore].");
			}

			if (legacyModel.TryGetCompatVariable("DetectionCriteriaFilter", out var detectionFilterVar))
			{
				detectionModel.Enabled = true;
				detectionModel.Criteria ??= new NxtApplicationCriteriaModel
				{
					Store = ApplicationStore.ARP
				};
				detectionModel.Criteria.Identifier = null;
				detectionModel.Criteria.Filter = ScriptBlock.Create(detectionFilterVar);
			}

			return detectionModel;
		}

		private static NxtSoftMigrationModel TranslateSoftmigrationModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var softMigrationModel = new NxtSoftMigrationModel();
			if (!string.IsNullOrWhiteSpace(legacyModel.SoftMigration?.File?.FullNameToCheck))
			{
				softMigrationModel.Enabled = true;
				softMigrationModel.Mode = SoftMigrationDetectionMode.File;
				softMigrationModel.Target = legacyModel.SoftMigration!.File!.FullNameToCheck;
				softMigrationModel.Version = legacyModel.SoftMigration.File?.VersionToCheck;
			}
			else if (!string.IsNullOrWhiteSpace(legacyModel.DisplayVersion)
					&& (!string.IsNullOrWhiteSpace(legacyModel.UninstallKey) || legacyModel.TryGetCompatVariable("DetectionCriteriaFilter", out _))
			)
			{
				softMigrationModel.Enabled = true;
				softMigrationModel.Mode = SoftMigrationDetectionMode.Detection;
				softMigrationModel.Version = legacyModel.DisplayVersion;
			}

			return softMigrationModel;
		}

		private static List<NxtCloseProcessesModel> TranslateCloseProcessModels(this NxtLegacyPackageConfigurationModel legacyModel)
		{
#pragma warning disable CS0618
			var closeProcessesList = legacyModel.AppKillProcesses?
				.Select(p => p.IsWQL
					? throw new NotSupportedException("WQL process detection is not supported in the new package configuration format.")
					: new NxtCloseProcessesModel()
					{
						Name = p.Name,
						Description = p.Description,
						AllowBlocking = !legacyModel.BlockExecution
					}
				)
				.ToList() ?? [];

			if (legacyModel.TryGetCompatVariable("CloseProcessesReopen", out var closeProcessesVar))
			{
				var entries = closeProcessesVar!
					.Split(',')
					.Select(e => Enum.TryParse<ReopenMode>(e.Trim(), true, out var varMode)
						? varMode
						: throw new InvalidDataException($"The value [{e}] of [CloseProcessesReopen] cannot be parsed into a [ReopenMode]."))
					.ToList();

				if (entries.Count != closeProcessesList.Count)
				{
					throw new InvalidDataException("[CloseProcessesReopen] was specified, but did not match the number of entries in [AskKillProcesses]. Mapping not possible");
				}
				for (var i = 0; i < entries.Count; i++)
				{
					closeProcessesList[i].ReopenMode = entries[i];
				}
			}

			return closeProcessesList;
#pragma warning restore CS0618
		}

		private static List<NxtShortcutModel> TranslateManagedShortcutModels(this NxtLegacyPackageConfigurationModel legacyModel)
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

		private static List<NxtApplicationCriteriaModel> TranslateManagedApplicationModels(this NxtLegacyPackageConfigurationModel legacyModel)
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

		private static NxtDeploymentContainerModel TranslateDeploymentContainerModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			return new NxtDeploymentContainerModel
			{
				InstallLocation = legacyModel.InstallLocation,
				Installation = legacyModel.TranslateInstallationModel(),
				Uninstallation = legacyModel.TranslateUninstallationModel()
			};
		}

		private static NxtInstallationModel TranslateInstallationModel(this NxtLegacyPackageConfigurationModel legacyModel)
		{
			var installModel = new NxtInstallationModel
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

			if (legacyModel.TryGetCompatVariable("DeploymentInstallationUpgradeMode", out var upgradeModeVar))
			{
				installModel.UpgradeMode = Enum.TryParse<UpgradeMode>(upgradeModeVar, true, out var varUpgradeMode)
					? varUpgradeMode
					: throw new InvalidDataException($"The value [{upgradeModeVar}] of [DeploymentInstallationUpgradeMode] cannot be parsed into an [ApplicationStore].");
			}

			return installModel;
		}

		private static NxtUninstallationModel TranslateUninstallationModel(this NxtLegacyPackageConfigurationModel legacyModel)
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

		private static Dictionary<string, object> TranslateVariables(this NxtLegacyPackageConfigurationModel legacyModel)
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
			variables["Legacy_ProductGUID"] = legacyModel.ProductGUID ?? string.Empty;
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

		private static List<SessionStateVariableEntry> GetLegacyVariables(IDictionary<string, object> adtEnvironment, NxtLegacyPackageConfigurationModel legacyModel)
		{
			var result = new List<SessionStateVariableEntry>();

			// Arch specific variables
			if (legacyModel.AppArch.Equals("x86", StringComparison.OrdinalIgnoreCase) || legacyModel.AppArch.Equals("arm", StringComparison.OrdinalIgnoreCase))
			{
				result.Add(new("ProgramFilesDir", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("ProgramFilesDirx86", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("ProgramW6432", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonFilesDir", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonFilesDirx86", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonProgramW6432", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("RegSoftwarePath", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("RegSoftwarePathx86", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("System", adtEnvironment["envSystemX86"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			}
			else
			{
				result.Add(new("ProgramFilesDir", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("ProgramFilesDirx86", adtEnvironment["envProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("ProgramW6432", adtEnvironment["envProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonFilesDir", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonFilesDirx86", adtEnvironment["envCommonProgramFilesW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("CommonProgramW6432", adtEnvironment["envCommonProgramFiles"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("RegSoftwarePath", adtEnvironment["envRegistrySoftware"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("RegSoftwarePathx86", adtEnvironment["envRegistrySoftwareW3264"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
				result.Add(new("System", adtEnvironment["envSystemX64"], string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			}

			result.Add(new("UserPartDir", string.Empty, string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			result.Add(new("AppLogFolder", "%LogFolder%", string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			result.Add(new("DirFiles", "%DirFiles%", string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			result.Add(new("DirSupportFiles", "%DirSupportFiles%", string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));
			result.Add(new SessionStateVariableEntry("PackageConfig", legacyModel, string.Empty, NxtPowerShell.GLOBAL_CONSTANT_OPTION));

			return result;
		}

		private static bool TryGetCompatVariable(this NxtLegacyPackageConfigurationModel legacyModel, string name, out string? value)
		{
			value = legacyModel.PackageSpecificVariablesRaw?.Find(psvr => psvr.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && !string.IsNullOrWhiteSpace(psvr.Value))?.Value;
			return value != null;
		}
	}
}
