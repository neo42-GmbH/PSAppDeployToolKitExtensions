using System;
using System.Collections.Generic;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Microsoft.PowerShell;
using System.Management.Automation.Language;
using System.Security.Principal;

namespace Neo42.DeployNxtApplication
{
	public static class DeployNxtApplication
	{
		private static readonly string _deployScript = Path.Combine(Path.GetDirectoryName(Application.ExecutablePath), "Deploy-Application.ps1");

		private static readonly List<string> _deployScriptArguments = [.. Environment.GetCommandLineArgs().Skip(1)];

		private static readonly string _deployDirectory = Path.GetDirectoryName(Application.ExecutablePath);

		private static readonly string _powerShellPath = Environment.Is64BitOperatingSystem && !Environment.Is64BitProcess
			? $"{Environment.GetFolderPath(Environment.SpecialFolder.Windows)}\\Sysnative\\WindowsPowerShell\\v1.0\\powershell.exe"
			: $"{Environment.GetFolderPath(Environment.SpecialFolder.System)}\\WindowsPowerShell\\v1.0\\powershell.exe";

		private static readonly bool _isAdmin = new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator);

		private static readonly bool _asAdmin = GetPowershellArgument([.. Environment.GetCommandLineArgs().Skip(1)], "DeploymentType", 0)?.EndsWith("UserPart") ?? true;

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

				Environment.Exit(
					ExecutePowerShell(
						_deployScript,
						_deployScriptArguments,
						_executionPolicy,
						_deployDirectory,
						_asAdmin
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

		private static int ExecutePowerShell(string file, IEnumerable<string> args, ExecutionPolicy execPolicy, string workingDir, bool asAdmin)
		{
			Environment.SetEnvironmentVariable("PSModulePath", null, EnvironmentVariableTarget.Process); // Clear the PSModulePath to avoid module loading issues.

			using var process = Process.Start(
				new ProcessStartInfo
				{
					FileName = _powerShellPath,
					Arguments = GetPowerShellArgumentString(file, args, execPolicy),
					WorkingDirectory = workingDir,
					WindowStyle = ProcessWindowStyle.Hidden,
					CreateNoWindow = true,
					UseShellExecute = asAdmin && !_isAdmin, // UseShellExecute must only be true if elevation is needed. Prevents duplicate UAC and issues with Process.Start() returning null
					Verb = asAdmin ? "runas" : null
				}
			);

			if (!process.WaitForExit(7200000)) // Wait for up to 120 minutes
			{
				process.Kill();
				throw new TimeoutException($"The PowerShell process '{_powerShellPath}' did not exit within the expected time limit.");
			}

			return process.ExitCode;
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

		private static string? GetPowershellArgument(this List<string> argumentList, string argument, uint? position = null)
		{
			if (!argumentList.Any())
			{
				return null;
			}

			if (position is not null && argumentList.Count >= position && argumentList.Take((int)position).All(s => !s.StartsWith("-")))
			{
				return argumentList[(int)position];
			}

			var index = argumentList.FindIndex(s => s.Equals("-" + argument, StringComparison.OrdinalIgnoreCase));
			if (index < 0)
			{
				return null;
			}

			var argumentString = argumentList[index];
			if (argumentString.StartsWith("-" + argument + ":", StringComparison.OrdinalIgnoreCase))
			{
				return argumentString.Split([':'], 2).Last();
			}

			if (argumentList.Count > index + 1 && !argumentList[index + 1].StartsWith("-"))
			{
				return argumentList[index + 1];
			}

			return null;
		}
	}
}
