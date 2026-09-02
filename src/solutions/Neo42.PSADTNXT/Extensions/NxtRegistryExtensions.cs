using System;
using System.Linq;
using Microsoft.Win32;

namespace PSADTNXT.Extensions
{
	public static class NxtRegistryExtensions
	{
		/// <summary>
		/// All registry views available to operating system.
		/// </summary>
		public static RegistryView[] GetAllViews()
		{
			return Environment.Is64BitOperatingSystem
				? [RegistryView.Registry32, RegistryView.Registry64]
				: [RegistryView.Registry32];
		}

		/// <summary>
		/// Deletes a registry key and all of its subkeys.
		/// </summary>
		/// <param name="key">The registry key to delete.</param>
		public static void DeleteTree(this RegistryKey key, bool throwOnMissingSubKey = false)
		{
			if (key == null)
			{
				throw new ArgumentNullException(nameof(key));
			}

			var baseKey = key.GetBaseKey();
			try
			{
				baseKey.DeleteSubKeyTree(key.Name.Substring(key.Name.IndexOf('\\') + 1), throwOnMissingSubKey);
			}
			finally
			{
				baseKey.Dispose();
			}
		}

		/// <summary>
		/// Deletes a registry key.
		/// </summary>
		/// <param name="key">The registry key to delete.</param>
		public static void Delete(this RegistryKey key, bool throwOnMissingSubKey = false)
		{
			if (key == null)
			{
				throw new ArgumentNullException(nameof(key));
			}

			var baseKey = key.GetBaseKey();
			try
			{
				baseKey.DeleteSubKey(key.Name.Substring(key.Name.IndexOf('\\') + 1), throwOnMissingSubKey);
			}
			finally
			{
				baseKey.Dispose();
			}
		}

		/// <summary>
		/// Gets the parent registry key of the specified key.
		/// </summary>
		/// <param name="key">The registry key whose parent is to be retrieved.</param>
		/// <param name="subKeyName">The name of the subkey within the parent key.</param>
		/// <param name="rights">The access rights to the parent key.</param>
		/// <returns>The parent registry key.</returns>
		public static RegistryKey GetParent(this RegistryKey key, bool writeable = false)
		{
			if (key == null)
			{
				throw new ArgumentNullException(nameof(key));
			}

			var keyPath = key.Name.Substring(
				key.Name.IndexOf('\\') + 1,
				key.Name.LastIndexOf('\\') - key.Name.IndexOf('\\')
			);

			using var baseKey = key.GetBaseKey();

			return baseKey
				.OpenSubKey(keyPath, writeable)
				?? throw new InvalidOperationException($"The parent key of '{key.Name}' is inaccessible.");
		}

		/// <summary>
		/// Gets the base registry key for the specified key.
		/// </summary>
		/// <param name="key">The registry key whose base key is to be retrieved.</param>
		/// <returns>The base registry key.</returns>
		public static RegistryKey GetBaseKey(this RegistryKey key)
		{
			if (key == null)
			{
				throw new ArgumentNullException(nameof(key));
			}

			return RegistryKey.OpenBaseKey(
				key.GetHive(),
				key.View
			);
		}

		/// <summary>
		/// Gets the hive of the specified registry key.
		/// </summary>
		/// <param name="key">The registry key whose hive is to be retrieved.</param>
		/// <returns>The hive of the registry key.</returns>
		public static RegistryHive GetHive(this RegistryKey key)
		{
			if (key == null)
			{
				throw new ArgumentNullException(nameof(key));
			}

			return GetHive(key.Name);
		}

		/// <summary>
		/// Gets the hive of the specified registry key by its name.
		/// </summary>
		/// <param name="keyName">The name of the registry key whose hive is to be retrieved.</param>
		/// <returns>The hive of the registry key.</returns>
		public static RegistryHive GetHive(string keyName)
		{
			if (string.IsNullOrWhiteSpace(keyName))
			{
				throw new ArgumentNullException(nameof(keyName));
			}

			var hiveName = keyName.Split(['\\'], 2).First().TrimEnd(':').ToUpper();

			return hiveName switch
			{
				"HKEY_LOCAL_MACHINE" or "HKLM" => RegistryHive.LocalMachine,
				"HKEY_CURRENT_USER" or "HKCU" => RegistryHive.CurrentUser,
				"HKEY_CLASSES_ROOT" or "HKCR" => RegistryHive.ClassesRoot,
				"HKEY_CURRENT_CONFIG" or "HKCC" => RegistryHive.CurrentConfig,
				"HKEY_PERFORMANCE_DATA" or "HKPD" => RegistryHive.PerformanceData,
				"HKEY_USERS" or "HKU" => RegistryHive.Users,
				_ => throw new ArgumentException("The registry key does not have a valid hive.", nameof(keyName)),
			};
		}

		/// <summary>
		/// Determines whether a character is a valid character for a registry path.
		/// </summary>
		/// <param name="c"> The character to check.</param>
		/// <returns>True if the character is a valid character for a registry path; otherwise, false.</returns>
		public static bool IsValidPathChar(char c)
		{
			return c is >= '\x20' and <= '\x7e';
		}
	}
}
