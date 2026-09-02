using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Management.Automation.Runspaces;
using Microsoft.PowerShell;
using Microsoft.PowerShell.Commands;
using Microsoft.Win32;
using PSADTNXT.Extensions;
using PSADTNXT.IO;

namespace PSADTNXT.Shell
{
	public static class NxtPowerShell
	{
		internal const ScopedItemOptions GLOBAL_CONSTANT_OPTION = ScopedItemOptions.Constant | ScopedItemOptions.AllScope;

		internal static readonly IReadOnlyCollection<SessionStateVariableEntry> StrictPreferenceVariables =
		[
			new SessionStateVariableEntry("ErrorActionPreference", ActionPreference.Stop, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("ProgressPreference", ActionPreference.SilentlyContinue, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("VerbosePreference", ActionPreference.SilentlyContinue, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("WarningPreference", ActionPreference.SilentlyContinue, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("InformationPreference", ActionPreference.SilentlyContinue, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("PSModuleAutoLoadingPreference", PSModuleAutoLoadingPreference.None, string.Empty, GLOBAL_CONSTANT_OPTION),
			new SessionStateVariableEntry("ConfirmPreference", ConfirmImpact.None, string.Empty, GLOBAL_CONSTANT_OPTION)
		];

		private static readonly IReadOnlyCollection<string> _strictModeExclusions = new HashSet<string>
		{
			"PropertyReferenceNotSupportedInDataSection",
			"MethodCallNotSupportedInDataSection",
			"OperatorNotSupportedInDataSection",
			"ScriptBlockNotSupportedInDataSection"
		};

		/// <summary>
		/// Characters that require escaping in PowerShell inline strings (e.g. when used in a command argument).
		/// </summary>
		private static readonly char[] _escapableCharacters = [' ', '\t', '\n', ';', '$', '{', '}', '"', '\''];

		/// <summary>
		/// Checks if the input string contains any characters that need to be escaped in PowerShell inline strings.
		/// </summary>
		/// <param name="input">The input string to check.</param>
		/// <returns>True if the input contains escapable characters; otherwise, false.</returns>
		public static bool ContainsEscapableCharacters(string input)
		{

			return input.IndexOfAny(_escapableCharacters) >= 0;
		}

		/// <summary>
		/// Converts a <see cref="PSObject"/> container to a <see cref="Hashtable"/> recursively.
		/// </summary>
		/// <remarks>
		/// Any non-property values in the <see cref="PSObject"/> will be lost in the conversion.
		/// </remarks>
		internal static Dictionary<string, object> ToDictionary(this PSObject psObject)
		{
			static ArrayList ConvertToArrayList(ICollection collection)
			{
				var list = new ArrayList();
				foreach (var item in collection)
				{
					if (item is PSObject itemPsObject)
					{
						_ = list.Add(itemPsObject.ToDictionary());
					}
					else if (item is not string and ICollection nestedCollection)
					{
						_ = list.Add(ConvertToArrayList(nestedCollection));
					}
					else
					{
						_ = list.Add(item);
					}
				}
				return list;
			}

			var dict = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
			foreach (var property in psObject.Properties)
			{
				if (property.Value is PSObject nestedPsObject)
				{
					dict[property.Name] = nestedPsObject.ToDictionary();
				}
				else if (property.Value is not string and ICollection collection)
				{
					dict[property.Name] = ConvertToArrayList(collection);
				}
				else
				{
					dict[property.Name] = property.Value;
				}
			}
			return dict;
		}

		/// <summary>
		/// Converts a <see cref="RegistryKey"/> to a PowerShell provider path.
		/// </summary>
		/// <param name="key">The registry key to convert.</param>
		/// <returns>The PowerShell provider path representing the key.</returns>
		internal static string ToPSProviderPath(this RegistryKey key)
		{
			var wow6432Node = key.View == RegistryView.Registry32 && Environment.Is64BitOperatingSystem;
			var parts = key.Name.Split('\\').ToList();
			var hive = key.GetHive();

			// Insert the WOW6432Node if needed
			if (wow6432Node && parts.Count > 1)
			{
				switch (hive)
				{
					case RegistryHive.CurrentUser:
					case RegistryHive.LocalMachine:
						if (parts[1].Equals("SOFTWARE", StringComparison.OrdinalIgnoreCase))
						{
							parts.Insert(2, "WOW6432Node");
						}
						break;
					case RegistryHive.Users:
						if (parts.Count > 2 && parts[2].Equals("SOFTWARE", StringComparison.OrdinalIgnoreCase))
						{
							parts.Insert(3, "WOW6432Node");
						}
						break;
					case RegistryHive.ClassesRoot:
					case RegistryHive.PerformanceData:
					case RegistryHive.CurrentConfig:
					default:
						break;
				}
			}

			return "Microsoft.PowerShell.Core\\Registry::" + string.Join("\\", parts);
		}

		/// <summary>
		/// Converts a PowerShell provider path to a <see cref="RegistryKey"/>.
		/// </summary>
		/// <param name="path">The PowerShell provider path to convert.</param>
		/// <param name="writable">If the key should be opened with write permission.</param>
		/// <returns>The registry key represented by the path.</returns>
		/// <exception cref="ArgumentException"/>
		/// <remarks>
		/// Paths are always assumed to be written for the 64-bit registry view. For accessing the 32-bit registry on 64-bit systems, use WOW6432Node in the path as needed.
		/// </remarks>
		public static RegistryKey? ToRegistryKeyFromPSProviderPath(this string path, bool writable = false)
		{
			var providerParts = path.Split(["::"], 2, StringSplitOptions.None);
			if (providerParts.Length > 1 && !providerParts.First().EndsWith("Registry", StringComparison.OrdinalIgnoreCase))
			{
				throw new ArgumentException("The provided path is not a valid registry provider path.", nameof(path));
			}

			var parts = providerParts.Last().Split('\\').ToList();
			var hive = NxtRegistryExtensions.GetHive(parts.First());
			using var baseKey = RegistryKey.OpenBaseKey(hive, RegistryView.Registry64);
			return baseKey.OpenSubKey(string.Join("\\", parts.Skip(1)), writable);
		}

		/// <summary>
		/// Imports a PowerShell data file (.psd1) and returns the resulting hashtable.
		/// </summary>
		/// <param name="path">The path to the .psd1 file.</param>
		/// <returns>The hashtable representing the contents of the .psd1 file.</returns>
		/// <exception cref="InvalidOperationException">Thrown if the file does not contain a valid hashtable.</exception>
		/// <exception cref="FileNotFoundException">Thrown if the file does not exist.</exception>
		internal static Hashtable ImportPsDataFile(string path)
		{
			if (!File.Exists(path))
			{
				throw new FileNotFoundException($"The file '{path}' does not exist.", path);
			}

			if (!TryGetPsDataFileHashtableAst(path, out var hashtableAst))
			{
				throw new InvalidOperationException($"The file '{path}' does not contain a valid data file.");
			}

			return (Hashtable)hashtableAst!.SafeGetValue();
		}

		/// <summary>
		/// Scans a PowerShell script root for the first Hashtable ast. Useful for PowerShell data file analysis.
		/// </summary>
		/// <param name="path">The path to the file.</param>
		/// <returns>The hashtable ast.</returns>
		/// <exception cref="InvalidOperationException">Thrown if the parser encounters errors.</exception>
		internal static bool TryGetPsDataFileHashtableAst(string path, out HashtableAst? hashtableAst)
		{
			var ast = Parser.ParseFile(path, out _, out var errors);
			if (errors.Length > 0)
			{
				throw new InvalidOperationException("The PowerShell file could not be parsed without errors.", new ParseException(errors));
			}

			hashtableAst = (HashtableAst?)ast.Find(static a => a is HashtableAst, false);
			return hashtableAst != null;
		}

		/// <summary>
		/// Determines if the given file must be signed in the current <see cref="ExecutionPolicy"/> context.
		/// </summary>
		/// <param name="filePath">The file to test.</param>
		/// <returns>True if signing is required, otherwise false.</returns>
		internal static bool RequiresSigning(string filePath)
		{
			return GetExecutionPolicy() switch
			{
				ExecutionPolicy.AllSigned => true,
				ExecutionPolicy.RemoteSigned => (int)(NxtPath.GetFileSecurityZone(filePath) ?? SecurityZone.URLZONE_LOCAL_MACHINE) > 2,
				ExecutionPolicy.Restricted => false,
				ExecutionPolicy.Bypass => false,
				ExecutionPolicy.Undefined => false,
				ExecutionPolicy.Unrestricted => false,
				_ => false
			};
		}

		/// <summary>
		/// Checks if a given <see cref="ScriptBlock"/> is safe to execute in a configuration context, based on the specified variable names and strict mode exclusions.
		/// </summary>
		/// <param name="scriptBlock">The <see cref="ScriptBlock"/> to check.</param>
		/// <param name="variableNames">The names of the variables that are allowed in the script block.</param>
		/// <param name="errors">An array of <see cref="ParseError"/> objects representing any errors found.</param>
		/// <returns>True if the script block is safe to execute; otherwise, false.</returns>
		internal static bool IsConfigSafe(ScriptBlock scriptBlock, IEnumerable<string> variableNames, out ParseError[] errors)
		{
			if (scriptBlock == null)
			{
				throw new ArgumentNullException(nameof(scriptBlock));
			}

			try
			{
				scriptBlock.CheckRestrictedLanguage([], variableNames, false);
			}
			catch (ParseException ex)
			{
				errors = [.. ex.Errors.Where(e => !_strictModeExclusions.Contains(e.ErrorId))];
				return errors.Length == 0;
			}

			errors = [];
			return true;
		}

		/// <summary>
		/// Invokes the current PowerShell to obtain the current <see cref="ExecutionPolicy"/>
		/// </summary>
		/// <returns>The current ExecutionPolicy</returns>
		internal static ExecutionPolicy GetExecutionPolicy()
		{
			using var powerShell = PowerShell.Create();
			return powerShell.AddCommand("Get-ExecutionPolicy").AddParameter("Scope", ExecutionPolicyScope.Process).Invoke<ExecutionPolicy>().First();
		}

		/// <summary>
		/// Run script in its own runspace with no commands and only the given variables available.
		/// </summary>
		/// <typeparam name="T">The expected output type.</typeparam>
		/// <param name="script">The script to run.</param>
		/// <param name="sessionVariables">The variables available to the session.</param>
		/// <returns>The result of the invocation.</returns>
		/// <exception cref="InvalidOperationException">Thrown if the output is not the expected or the PowerShell session logged issues.</exception>
		internal static T PsInvokeSafe<T>(string script, IEnumerable<SessionStateVariableEntry> sessionVariables)
		{
			using var powerShell = PowerShell.Create(GetExpansionSessionState(sessionVariables));

			var result = powerShell.AddScript("Set-StrictMode -Version 3.0")
				.AddScript(script)
				.Invoke<T>()
				.FirstOrDefault();

			return powerShell.HadErrors || result is null
				? throw new InvalidOperationException("The specified configuration file could not be evaluated.", new AggregateException(powerShell.Streams.Error.Select(e => e.Exception)))
				: result;
		}

		/// <summary>
		/// Use the given PowerShell to expand a string without the use of methods or commands.
		/// </summary>
		/// <param name="powershell">The PowerShell to use.</param>
		/// <param name="input">The string to expand.</param>
		/// <returns>The expanded string.</returns>
		/// <exception cref="InvalidOperationException">Thrown if the expansion was unsuccessful.</exception>
		internal static string ExpandString(this PowerShell powershell, string input)
		{
			powershell.Commands.Clear();
			var result = powershell
				.AddScript($"\"{input.Replace("`", "``").Replace("\"", "`\"")}\"")
				.Invoke<string>()
				.FirstOrDefault()
				?? string.Empty;

			return !powershell.HadErrors
				? result
				: throw new InvalidOperationException("The string expansion had errors.", new AggregateException(powershell.Streams.Error.Select(e => e.Exception)));
		}

		/// <summary>
		/// Converts the properties of a <see cref="PSObject"/> to session state variables.
		/// </summary>
		/// <param name="psObj">The object to convert.</param>
		/// <param name="scopedItemOptions">Scoping options to apply to the entries.</param>
		/// <returns>The list of variables.</returns>
		internal static List<SessionStateVariableEntry> ToSessionStateVariables(PSObject psObj, ScopedItemOptions scopedItemOptions)
		{
			return [.. psObj.Properties.Select(p => new SessionStateVariableEntry(p.Name, p.Value, string.Empty, scopedItemOptions))];
		}

		/// <summary>
		/// Converts the properties of a dictionary to session state variables.
		/// </summary>
		/// <param name="dict">The object to convert.</param>
		/// <param name="scopedItemOptions">Scoping options to apply to the entries.</param>
		/// <returns>The list of variables.</returns>
		internal static List<SessionStateVariableEntry> ToSessionStateVariables(IDictionary<string, object> dict, ScopedItemOptions scopedItemOptions)
		{
			return [.. dict.Keys.Select(p => new SessionStateVariableEntry(p, dict[p], string.Empty, scopedItemOptions))];
		}

		/// <summary>
		/// Converts <see cref="PSVariable"/>s to session state variables.
		/// </summary>
		/// <param name="psVariables">The object(s) to convert.</param>
		/// <param name="scopedItemOptions">Scoping options to apply to the entries.</param>
		/// <returns>The list of variables.</returns>
		internal static List<SessionStateVariableEntry> ToSessionStateVariables(IEnumerable<PSVariable> psVariables, ScopedItemOptions scopedItemOptions)
		{
			return [.. psVariables.Select(v => new SessionStateVariableEntry(v.Name, v.Value, string.Empty, scopedItemOptions))];
		}

		/// <summary>
		/// Returns a strict expansion session state that only exposes given variables.
		/// </summary>
		/// <param name="variables">The variables to expose.</param>
		/// <returns>The initial session state.</returns>
		internal static InitialSessionState GetExpansionSessionState(IEnumerable<SessionStateVariableEntry> variables)
		{
			var allVariables = new List<SessionStateVariableEntry>(StrictPreferenceVariables);
			allVariables.AddRange(variables.Where(v => !StrictPreferenceVariables.Any(spv => string.Equals(spv.Name, v.Name, StringComparison.OrdinalIgnoreCase))));

			var iss = InitialSessionState.CreateRestricted(SessionCapabilities.Language);
			iss.LanguageMode = PSLanguageMode.ConstrainedLanguage;
			iss.ThrowOnRunspaceOpenError = true;
			iss.DisableFormatUpdates = true;
			iss.Commands.Add(new SessionStateCmdletEntry("Set-StrictMode", typeof(SetStrictModeCommand), string.Empty));
			iss.Variables.Add(allVariables);
			return iss;
		}
	}
}
