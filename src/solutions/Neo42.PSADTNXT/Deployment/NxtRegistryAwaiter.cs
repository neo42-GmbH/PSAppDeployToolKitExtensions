using System;
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
