using System;
using System.Collections;
using PSADT.ProcessManagement;
using PSADTNXT.IO;

namespace PSADTNXT.ProcessManagement
{
	public sealed record NxtCloseProcess
	{
		public ProcessDefinition ProcessDefinition { get; }

		public bool AllowBlocking { get; }

		public ReopenMode ReopenMode { get; }

		public NxtCloseProcess(string name)
		{
			if (string.IsNullOrWhiteSpace(name))
			{
				throw new ArgumentException("Process name cannot be null or whitespace.", nameof(name));
			}

			ProcessDefinition = new ProcessDefinition(NxtPath.GetExecutableName(name));
			AllowBlocking = true;
			ReopenMode = ReopenMode.None;
		}

		public NxtCloseProcess(string name, string description, bool allowBlocking = true, ReopenMode reopenMode = ReopenMode.None)
		{
			if (string.IsNullOrWhiteSpace(name))
			{
				throw new ArgumentException("Process name cannot be null or whitespace.", nameof(name));
			}

			ProcessDefinition = new ProcessDefinition(NxtPath.GetExecutableName(name), description);
			AllowBlocking = allowBlocking;
			ReopenMode = reopenMode;
		}

		public NxtCloseProcess(Hashtable parameters)
		{
			if (parameters == null)
			{
				throw new ArgumentNullException(nameof(parameters));
			}

			var name = parameters["Name"] is string paramName
				? NxtPath.GetExecutableName(paramName)
				: throw new ArgumentException("Parameter 'Name' is required and must be of type string.", nameof(parameters));
			var description = parameters["Description"] as string ?? string.Empty;

			ProcessDefinition = new ProcessDefinition(name, description);
			AllowBlocking = parameters["AllowBlocking"] is not bool ab || ab;
			ReopenMode = parameters["ReopenMode"] is ReopenMode rm ? rm : ReopenMode.None;
		}

		public static implicit operator NxtCloseProcess(Hashtable parameters)
		{
			return FromHashtable(parameters);
		}

		public static NxtCloseProcess FromHashtable(Hashtable parameters)
		{
			return new NxtCloseProcess(parameters);
		}

		public static implicit operator ProcessDefinition(NxtCloseProcess closeProcess)
		{
			return closeProcess.ToProcessDefinition();
		}

		public ProcessDefinition ToProcessDefinition()
		{
			return ProcessDefinition;
		}

		public override string ToString()
		{
			return ProcessDefinition.Name;
		}
	}
}
