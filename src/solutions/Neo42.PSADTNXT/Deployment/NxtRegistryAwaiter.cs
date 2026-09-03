using System;
using System.Collections;
using Microsoft.Win32;
using PSADTNXT.Shell;

namespace PSADTNXT.Deployment
{
	public sealed class NxtRegistryAwaiter : INxtAwaiter
	{
		public string Key { get; }

		public string? Name { get; }

		public string? Value { get; }

		public bool Exists { get; } = true;

		public TimeSpan Timeout { get; } = TimeSpan.FromSeconds(30);

		public NxtRegistryAwaiter(string key, string? name = null, string? value = null, bool exists = true, TimeSpan? timeout = null)
		{
			Key = key;
			Name = name;
			Value = value;
			Exists = exists;
			if (timeout.HasValue)
			{
				Timeout = timeout.Value;
			}
		}

		public static implicit operator NxtRegistryAwaiter(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtRegistryAwaiter FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var key = hashtable.ContainsKey("Key") && hashtable["Key"] is string keyValue
				? keyValue
				: throw new ArgumentException("Missing or invalid 'Key' value in the provided hashtable.");

			var name = hashtable.ContainsKey("Name")
				? hashtable["Name"] is string nameValue ? nameValue : throw new ArgumentException($"Invalid value for Name: {hashtable["Name"]}")
				: null;

			var value = hashtable.ContainsKey("Value")
				? hashtable["Value"] is string valueValue ? valueValue : throw new ArgumentException($"Invalid value for Value: {hashtable["Value"]}")
				: null;

#pragma warning disable IDE0075
			var exists = hashtable.ContainsKey("Exists")
				? hashtable["Exists"] is bool existsValue ? existsValue : throw new ArgumentException($"Invalid value for Exists: {hashtable["Exists"]}")
				: true;
#pragma warning restore IDE0075

			var timeout = hashtable.ContainsKey("Timeout")
				? TimeSpan.TryParse(hashtable["Timeout"]?.ToString(), out var timeoutValue) ? timeoutValue : throw new ArgumentException($"Invalid value for Timeout: {hashtable["Timeout"]}")
				: TimeSpan.FromSeconds(30);

			return new NxtRegistryAwaiter(key, name, value, exists, timeout);
		}

		public bool Evaluate()
		{
			if (Key.ToRegistryKeyFromPSProviderPath() is not RegistryKey key)
			{
				return !Exists;
			}

			if (!string.IsNullOrWhiteSpace(Name))
			{
				var value = key.GetValue(Name);
				if (value == null)
				{
					return !Exists;
				}

				if (!string.IsNullOrWhiteSpace(Value))
				{
					return Exists == string.Equals(value.ToString(), Value, StringComparison.OrdinalIgnoreCase);
				}
			}

			return Exists;
		}

		public override string ToString()
		{
			return Key;
		}
	}
}
