using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using PSADTNXT.ComponentModel.DataAnnotations;

namespace PSADTNXT.Deployment.Configuration.Legacy
{
	public sealed record NxtLegacyPackageConfigurationModel : IValidatableObject
	{
		[Required]
		public string ConfigVersion { get; set; } = null!;

		public string ScriptAuthor { get; set; } = string.Empty;

		[ValidDateTime(Format = "dd/MM/yyyy")]
		public string ScriptDate { get; set; } = string.Empty;

		public string InventoryID { get; set; } = string.Empty;

		public string Description { get; set; } = string.Empty;

		[Required]
		public string InstallMethod { get; set; } = string.Empty;

		[Required]
		public string UninstallMethod { get; set; } = string.Empty;

		[Required]
		[ValidSet(Values = ["Install", "MSIRepair", "Reinstall"])]
		public string ReinstallMode { get; set; } = string.Empty;

		public bool MSIInplaceUpgradeable { get; set; }

		public bool MSIDowngradeable { get; set; }

		public NxtLegacySoftMigrationModel? SoftMigration { get; set; }

		public string TestedOn { get; set; } = string.Empty;

		public string Dependencies { get; set; } = string.Empty;

		public string LastChange { get; set; } = string.Empty;

		[RegularExpression(@"^\d+$")]
		public string Build { get; set; } = string.Empty;

		[Required]
		public string AppArch { get; set; } = string.Empty;

		[Required]
		[ValidFileName]
		public string AppVendor { get; set; } = string.Empty;

		[Required]
		[ValidFileName]
		public string AppName { get; set; } = string.Empty;

		[Required]
		[ValidVersion]
		public string AppVersion { get; set; } = string.Empty;

		[RegularExpression(@"^\d+$")]
		public string AppRevision { get; set; } = string.Empty;

		public string AppLang { get; set; } = string.Empty;

		[Obsolete("Value is not used anymore.")]
		public string ProductGUID { get; set; } = string.Empty;

		[Obsolete("Value is not used anymore.")]
		public bool RemovePackagesWithSameProductGUID { get; set; }

		[Required]
		[ValidGuid]
		public string PackageGUID { get; set; } = string.Empty;

		public List<NxtLegacyDependentPackageModel>? DependentPackages { get; set; }

		public string RegPackagesKey { get; set; } = string.Empty;

		public string UninstallDisplayName { get; set; } = string.Empty;

		public string AppRootFolder { get; set; } = string.Empty;

		[Obsolete("Value is now hardcoded.")]
		public string App { get; set; } = string.Empty;

		public bool UninstallOld { get; set; }

		public uint Reboot { get; set; }

		public bool UserPartOnInstallation { get; set; }

		public bool UserPartOnUninstallation { get; set; }

		public string UserPartRevision { get; set; } = string.Empty;

		public bool HidePackageUninstallButton { get; set; }

		public bool HidePackageUninstallEntry { get; set; }

		public string DisplayVersion { get; set; } = string.Empty;

		[Obsolete("This metadata was not tied to logic. Use Variables instead.")]
		public string InstallerVersion { get; set; } = string.Empty;

		public string UninstallKey { get; set; } = string.Empty;

		public bool UninstallKeyIsDisplayName { get; set; }

		public bool UninstallKeyContainsWildCards { get; set; }

		public bool UninstallKeyContainsExpandVariables { get; set; }

		public List<string>? DisplayNamesToExcludeFromAppSearches { get; set; }

		[ValidPath(Root = ValidPathRoot.Rooted)]
		public string InstallLocation { get; set; } = string.Empty;

		public string InstLogFile { get; set; } = string.Empty;

		public string UninstLogFile { get; set; } = string.Empty;

		public string InstFile { get; set; } = string.Empty;

		public string InstPara { get; set; } = string.Empty;

		public bool AppendInstParaToDefaultParameters { get; set; }

		public string AcceptedInstallExitCodes { get; set; } = string.Empty;

		public string AcceptedInstallRebootCodes { get; set; } = string.Empty;

		public string UninstFile { get; set; } = string.Empty;

		public string UninstPara { get; set; } = string.Empty;

		public bool AppendUninstParaToDefaultParameters { get; set; }

		public string AcceptedUninstallExitCodes { get; set; } = string.Empty;

		public string AcceptedUninstallRebootCodes { get; set; } = string.Empty;

		public List<NxtLegacyAppKillProcessModel>? AppKillProcesses { get; set; }

		[Obsolete("Value has been moved to toolkit settings.")]
		public bool BlockExecution { get; set; }

		public NxtLegacyConditionCheckContainerModel? TestConditionsPreSetupSuccessCheck { get; set; }

		public List<string>? CommonDesktopShortcutsToDelete { get; set; }

		public List<NxtLegacyShortcutCopyModel>? CommonStartMenuShortcutsToCopyToCommonDesktop { get; set; }

		public List<NxtLegacyKeyHideModel>? UninstallKeysToHide { get; set; }

		public List<NxtLegacyVariableModel>? PackageSpecificVariablesRaw { get; set; }

		public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
		{
			var results = new List<ValidationResult>();
			if (SoftMigration is not null)
			{
				_ = Validator.TryValidateObject(SoftMigration, new ValidationContext(SoftMigration), results, true);
			}
			DependentPackages?.ForEach(p => _ = Validator.TryValidateObject(p, new ValidationContext(p), results, true));
			AppKillProcesses?.ForEach(p => _ = Validator.TryValidateObject(p, new ValidationContext(p), results, true));
			if (TestConditionsPreSetupSuccessCheck is not null)
			{
				_ = Validator.TryValidateObject(TestConditionsPreSetupSuccessCheck, new ValidationContext(TestConditionsPreSetupSuccessCheck), results, true);
			}
			CommonStartMenuShortcutsToCopyToCommonDesktop?.ForEach(s => _ = Validator.TryValidateObject(s, new ValidationContext(s), results, true));
			UninstallKeysToHide?.ForEach(k => _ = Validator.TryValidateObject(k, new ValidationContext(k), results, true));
			PackageSpecificVariablesRaw?.ForEach(v => _ = Validator.TryValidateObject(v, new ValidationContext(v), results, true));
			return results;
		}
	}
}
