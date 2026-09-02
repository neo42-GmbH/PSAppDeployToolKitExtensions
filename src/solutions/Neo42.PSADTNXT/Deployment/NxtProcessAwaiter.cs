using System;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;
using PSADTNXT.IO;

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
