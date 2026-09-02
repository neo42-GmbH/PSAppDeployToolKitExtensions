using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Management.Automation.Runspaces;
using System.Runtime.Serialization.Json;
using System.Text;
using PSADTNXT.Collections;
using PSADTNXT.Deployment.Configuration.Legacy;
using PSADTNXT.Shell;

namespace PSADTNXT.Deployment.Configuration
{
	public static class NxtPackageConfigurationFactory
	{
		public static NxtPackageConfigurationModel CreateFrom(string filePath, IDictionary<string, object> adtEnvironment, params SessionStateVariableEntry[] extraVariables)
		{
			/* Not compatible in 4.1
			// Check if execution policy requires the file to be signed and if so, verify the signature
			if (NxtPowerShell.RequiresSigning(filePath) && !FileSystemUtilities.IsAuthenticodeTrusted(filePath))
			{
				throw new SecurityException($"The execution policy on this system requires files to be signed. The specified configuration file '{filePath}' is not signed with a trusted signature.");
			}
			*/

			// Parse the actual file content of the file.
			var ast = Parser.ParseFile(filePath, out _, out var errors);
			if (errors.Length > 0)
			{
				throw new ParseException(errors);
			}

			// Collect all variables available for the expansion
			var sessionVariables = NxtPowerShell.ToSessionStateVariables(adtEnvironment, NxtPowerShell.GLOBAL_CONSTANT_OPTION).Concat(extraVariables);

			// Check if the file content is safe to execute with the given variables
			if (!NxtPowerShell.IsConfigSafe(ast.GetScriptBlock(), sessionVariables.Select(v => v.Name).Concat(["_", "PSItem"]), out var safetyErrors))
			{
				throw new InvalidDataException("The specified configuration file contains expressions that are not safe to execute.", new ParseException(safetyErrors));
			}

			// Apply data file logic by finding the first hashtable in the file
			if (ast.Find(a => a is HashtableAst, false) is not HashtableAst dataAst)
			{
				throw new InvalidDataException("The specified configuration file does not contain a valid PowerShell Data File hashtable.");
			}

			// Invoke the hashtable ast as a script and map the resulting hashtable to the configuration model
			var result = DictionaryMapper.Create<NxtPackageConfigurationModel>(NxtPowerShell.PsInvokeSafe<Hashtable>(dataAst.Extent.Text, sessionVariables));

			// Validate the resulting configuration model
			Validate(result);

			return result;
		}

		public static NxtLegacyPackageConfigurationModel CreateLegacyFrom(string filePath, IDictionary<string, object> adtEnvironment, params SessionStateVariableEntry[] extraVariables)
		{
			var serializer = new DataContractJsonSerializer(typeof(NxtLegacyPackageConfigurationModel));
			using var ms = new MemoryStream(Encoding.UTF8.GetBytes(File.ReadAllText(filePath, Encoding.UTF8)));

			if (serializer.ReadObject(ms) is not NxtLegacyPackageConfigurationModel result)
			{
				throw new InvalidDataException($"The file '{filePath}' could not be parsed into a '{nameof(NxtLegacyPackageConfigurationModel)}'.");
			}

			if (!Version.TryParse(result.ConfigVersion, out var configVersion) || configVersion < NxtLegacyTranslations.MinimumLegacyConfigVersion)
			{
				throw new NotSupportedException($"The legacy configuration version '{result.ConfigVersion}' is not supported. The minimum supported version is {NxtLegacyTranslations.MinimumLegacyConfigVersion}.");
			}

			result.Expand(adtEnvironment, extraVariables);

			Validate(result);

			return result;
		}

		public static NxtPackageConfigurationModel Translate(this NxtLegacyPackageConfigurationModel input)
		{
			return NxtLegacyTranslations.Translate(input);
		}

		private static void Validate(object model)
		{
			var validationResults = new List<ValidationResult>();
			if (!Validator.TryValidateObject(model, new ValidationContext(model), validationResults, true))
			{
				throw new ValidationException($"Validation failed with:\n * {string.Join("\n * ", validationResults.Select(r => r.ErrorMessage))}", new AggregateException(validationResults.Select(r => new ValidationException(r, null, null))));
			}
		}
	}
}
