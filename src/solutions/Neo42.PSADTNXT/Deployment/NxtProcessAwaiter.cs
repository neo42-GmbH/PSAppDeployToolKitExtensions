using System;
using System.Collections;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;

namespace PSADTNXT.Deployment
{
	public sealed class NxtProcessAwaiter : INxtAwaiter
	{
		public string Name { get; }

		public bool Exists { get; } = true;

		public TimeSpan Timeout { get; } = TimeSpan.FromSeconds(30);

		private readonly WildcardPattern _pattern;

		public NxtProcessAwaiter(string name, bool exists = true, TimeSpan? timeout = null)
		{
			Name = name;
			Exists = exists;
			Timeout = timeout ?? TimeSpan.FromSeconds(30);
			_pattern = new WildcardPattern(Name, WildcardOptions.IgnoreCase);
		}

		public static implicit operator NxtProcessAwaiter(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtProcessAwaiter FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var name = hashtable.ContainsKey("Name") && hashtable["Name"] is string nameValue
				? nameValue
				: throw new ArgumentException("Missing or invalid 'Name' value in the provided hashtable.");

#pragma warning disable IDE0075
			var exists = hashtable.ContainsKey("Exists")
				? hashtable["Exists"] is bool existsValue ? existsValue : throw new ArgumentException($"Invalid value for Exists: {hashtable["Exists"]}")
				: true;
#pragma warning restore IDE0075

			var timeout = hashtable.ContainsKey("Timeout")
				? TimeSpan.TryParse(hashtable["Timeout"]?.ToString(), out var timeoutValue) ? timeoutValue : throw new ArgumentException($"Invalid value for Timeout: {hashtable["Timeout"]}")
				: TimeSpan.FromSeconds(30);

			return new NxtProcessAwaiter(name, exists, timeout);
		}

		public bool Evaluate()
		{
			return Process.GetProcesses().Any(p => _pattern.IsMatch(p.ProcessName));
		}

		public override string ToString()
		{
			return Name;
		}
	}
}
