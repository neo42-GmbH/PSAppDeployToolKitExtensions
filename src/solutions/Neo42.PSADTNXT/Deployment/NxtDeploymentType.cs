using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using PSADT.Module;

namespace PSADTNXT.Deployment
{
	/// <summary>
	/// Represents the Neo42.Extension deployment type. Can be implicitly converted to and from <see cref="DeploymentType"/>.
	/// Supports methods for identifying specific modes of deployment.
	/// </summary>
	/// <seealso cref="DeploymentType"/>
	public sealed record NxtDeploymentType
	{
		// Cache of valid type names
		private static readonly ReadOnlyCollection<string> _typeNames = typeof(NxtDeploymentType)
			.GetProperties(BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly)
			.Select(p => p.Name)
			.ToList()
			.AsReadOnly();

		// Defined deployment types
		public static NxtDeploymentType Install { get; } = Create();

		public static NxtDeploymentType Uninstall { get; } = Create();

		public static NxtDeploymentType Repair { get; } = Create();

		public static NxtDeploymentType InstallUserPart { get; } = Create();

		public static NxtDeploymentType UninstallUserPart { get; } = Create();

		public static NxtDeploymentType TriggerInstallUserPart { get; } = Create();

		public static NxtDeploymentType TriggerUninstallUserPart { get; } = Create();

		// Public properties
		public string TypeName { get; }

		public bool IsUserPart { get; }

		public bool IsMachinePart { get; }

		public bool IsTrigger { get; }

		public bool IsInstall { get; }

		public bool IsUninstall { get; }

		public NxtDeploymentType(string typeName)
		{
			TypeName = _typeNames.FirstOrDefault(tn => string.Equals(tn, typeName, StringComparison.OrdinalIgnoreCase))
				?? throw new ArgumentException($"Invalid deployment type name '{typeName}'.", nameof(typeName));

			IsUserPart = TypeName.EndsWith("UserPart");
			IsMachinePart = !IsUserPart;
			IsTrigger = TypeName.StartsWith("Trigger");
			IsInstall = TypeName.Contains("Install") || TypeName.Equals("Repair");
			IsUninstall = !IsInstall;
		}

		public static implicit operator NxtDeploymentType(DeploymentType type)
		{
			return FromDeploymentType(type);
		}

		public static NxtDeploymentType FromDeploymentType(DeploymentType type)
		{
			return new NxtDeploymentType(type.ToString());
		}

		public static implicit operator DeploymentType(NxtDeploymentType type)
		{
			return type.ToDeploymentType();
		}

		public DeploymentType ToDeploymentType()
		{
			return TypeName == "Repair" ? DeploymentType.Repair : IsUninstall ? DeploymentType.Uninstall : DeploymentType.Install;
		}

		public static implicit operator NxtDeploymentType(string typeName)
		{
			return FromString(typeName);
		}

		public static NxtDeploymentType FromString(string typeName)
		{
			return new NxtDeploymentType(typeName);
		}

		public override string ToString()
		{
			return TypeName;
		}

		private static NxtDeploymentType Create([CallerMemberName] string? name = null)
		{
			return new NxtDeploymentType(name ?? throw new ArgumentNullException(nameof(name)));
		}
	}
}
