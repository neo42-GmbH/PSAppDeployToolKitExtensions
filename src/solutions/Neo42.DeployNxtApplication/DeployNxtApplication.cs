using System;
using System.Collections.Generic;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Microsoft.PowerShell;
using System.Management.Automation.Language;
using System.Text.RegularExpressions;

namespace Neo42.DeployNxtApplication
{
	public static class DeployNxtApplication
	{
		private static readonly string _deployScript = Path.Combine(Path.GetDirectoryName(Application.ExecutablePath), "Deploy-Application.ps1");

		private static readonly string _deployDirectory = Path.GetDirectoryName(Application.ExecutablePath);

		private static readonly string _powerShellPath = Environment.Is64BitOperatingSystem && !Environment.Is64BitProcess
			? $"{Environment.GetFolderPath(Environment.SpecialFolder.Windows)}\\Sysnative\\WindowsPowerShell\\v1.0\\powershell.exe"
			: $"{Environment.GetFolderPath(Environment.SpecialFolder.System)}\\WindowsPowerShell\\v1.0\\powershell.exe";

		private static readonly char[] _stringMarker = ['\'', '"'];

		private static readonly List<string> _deployScriptArguments = [.. Environment.GetCommandLineArgs().Skip(1)];

		private static readonly string _deploymentType = GetPowershellArgumentValue(_deployScriptArguments, "DeploymentType", 0) ?? "Install";

		private static readonly bool _asAdmin = !_deploymentType.EndsWith("UserPart", StringComparison.OrdinalIgnoreCase);

		private static readonly bool _isTrigger = _deploymentType.StartsWith("Trigger", StringComparison.OrdinalIgnoreCase);

		private const int ERROR_EXIT_CODE = 60010;

		private static ExecutionPolicy _executionPolicy = ExecutionPolicy.Default;

		public static void Main()
		{
			try
			{
				if (!File.Exists(_deployScript))
				{
					throw new FileNotFoundException($"The deployment script '{_deployScript}' does not exist.");
				}

				if (!File.Exists(_powerShellPath))
				{
					throw new FileNotFoundException($"The PowerShell executable '{_powerShellPath}' does not exist.");
				}

				LoadSettings();

				if (_isTrigger)
				{
					var deploymentTypeIndex = GetPowershellArgumentValueIndex(_deployScriptArguments, "DeploymentType", 0);
					_deployScriptArguments[deploymentTypeIndex] = Regex.Replace(_deployScriptArguments[deploymentTypeIndex], @"\bTrigger", string.Empty, RegexOptions.IgnoreCase);
				}

				Environment.Exit(
					ExecutePowerShell(
						_deployScript,
						_deployScriptArguments,
						_executionPolicy,
						_deployDirectory,
						_asAdmin,
						_isTrigger
					)
				);
			}
			catch (Exception ex)
			{
				_ = MessageBox.Show($"{ex.Message}\n\n{ex.StackTrace}", $"{Application.ProductName} {Application.ProductVersion}", MessageBoxButtons.OK, MessageBoxIcon.Error, MessageBoxDefaultButton.Button1);
			}
			finally
			{
				Environment.Exit(ERROR_EXIT_CODE);
			}
		}

		private static void LoadSettings()
		{
			var configLoadOrder = new List<string>()
			{
				Path.Combine(_deployDirectory, "PSAppDeployToolkit.Neo42.Extensions", "Config", "config.psd1"),
				Path.Combine(_deployDirectory, "Config", "config.psd1")
			};
			configLoadOrder.AddRange(Directory.EnumerateDirectories(_deployDirectory, "Overrides.*").Select(d => Path.Combine(d, "Config", "config.psd1")));
			_ = configLoadOrder.RemoveAll(f => !File.Exists(f));

			foreach (var configPath in configLoadOrder)
			{
				var config = ImportPsDataFile(configPath);
				if (config["NXT"] is not Hashtable nxtSettings)
				{
					continue;
				}

				if (nxtSettings["PowerShell"] is Hashtable powerShellSettings && powerShellSettings["ExecutionPolicy"] is string execPolicyStr && Enum.TryParse(execPolicyStr, out ExecutionPolicy execPolicy))
				{
					_executionPolicy = execPolicy;
				}
			}
		}

		private static string GetPowerShellArgumentString(string file, IEnumerable<string> args, ExecutionPolicy execPolicy)
		{
			return $"-NoP -NoL -NonI -EP {execPolicy} -C \"&{{&'{file}' "
				+ string.Join(" ", args.Select(s => s.Any(char.IsWhiteSpace) ? $"'{s}'" : s))
				+ ";exit(@(!$?;gv LASTEXITCODE -va -ea 0)[-1])\"}";
		}

		private static int ExecutePowerShell(string file, IEnumerable<string> args, ExecutionPolicy execPolicy, string workingDir, bool asAdmin, bool detached)
		{
			Environment.SetEnvironmentVariable("PSModulePath", null, EnvironmentVariableTarget.Process); // Clear the PSModulePath to avoid module loading issues.

			using var process = Process.Start(
				new ProcessStartInfo
				{
					FileName = _powerShellPath,
					Arguments = GetPowerShellArgumentString(file, args, execPolicy),
					WorkingDirectory = workingDir,
					WindowStyle = ProcessWindowStyle.Hidden,
					UseShellExecute = true,
					Verb = asAdmin ? "runas" : null
				}
			);

			if (!detached)
			{
				if (!process.WaitForExit(7200000)) // Wait for up to 120 minutes
				{
					process.Kill();
					throw new TimeoutException($"The PowerShell process '{_powerShellPath}' did not exit within the expected time limit.");
				}
				return process.ExitCode;
			}
			else
			{
				return 0;
			}
		}

		private static Hashtable ImportPsDataFile(string path)
		{
			var ast = Parser.ParseFile(path, out _, out var errors);
			if (errors.Length > 0)
			{
				throw new InvalidOperationException($"{string.Join(", ", errors.Select(static e => e.Message))}");
			}

			if (ast.Find(static a => a is HashtableAst, false) is not HashtableAst hashtable)
			{
				throw new InvalidOperationException($"The file '{path}' does not contain a valid hashtable.");
			}

			return (Hashtable)hashtable.SafeGetValue();
		}

		private static string? GetPowershellArgumentValue(this List<string> argumentList, string argument, uint? position = null)
		{
			var index = GetPowershellArgumentValueIndex(argumentList, argument, position);
			if (index < 0)
			{
				return null;
			}

			var argumentString = argumentList[index];

			if (argumentString.StartsWith("-" + argument + ":", StringComparison.OrdinalIgnoreCase))
			{
				argumentString = argumentString.Split([':'], 2).Last();
			}

			if (argumentString.Length >= 2
				&& argumentString.First() is char startChar
				&& argumentString.Last() == startChar
				&& _stringMarker.Contains(startChar)
			)
			{
				argumentString = argumentString.Substring(1, argumentString.Length - 2);
			}

			return argumentString;
		}

		private static int GetPowershellArgumentValueIndex(this List<string> argumentList, string argument, uint? position = null)
		{
			var index = argumentList.FindIndex(s => s.Equals("-" + argument, StringComparison.OrdinalIgnoreCase) || s.StartsWith("-" + argument + ":", StringComparison.OrdinalIgnoreCase));
			if (index >= 0)
			{
				if (argumentList[index].StartsWith("-" + argument + ":", StringComparison.OrdinalIgnoreCase))
				{
					return index;
				}

				return argumentList.Count > index + 1 && !argumentList[index + 1].StartsWith("-") ? index + 1 : -1;
			}

			if (position is not null && argumentList.Count > position && argumentList.Take((int)position + 1).All(s => !s.StartsWith("-")))
			{
				return (int)position;
			}

			return -1;
		}
	}
}
