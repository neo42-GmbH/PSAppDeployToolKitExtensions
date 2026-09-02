using System;
using System.Management.Automation;
using System.Reflection;
using System.Security.Principal;

namespace PSADTNXT.Attributes
{
	/// <summary>
	/// Transforms objects into a <see cref="IdentityReference"/>.
	/// </summary>
	[Obsolete("Backport from PSADT 4.2 for compatibility. Migrate once on 4.2")]
	public sealed class IdentityReferenceTransformationAttribute : ArgumentTransformationAttribute
	{
		/// <summary>
		/// Transforms input object into base <see cref="IdentityReference"/> objects for consumption in downstream PowerShell functions.
		/// Supported types:
		///  * <see cref="IdentityReference"/>
		///  * <see cref="WindowsIdentity"/>
		///  * <see cref="WellKnownSidType"/>
		///  * LocalPrincipal
		///  * <see cref="string"/> representing the above
		/// </summary>
		/// <param name="engineIntrinsics">The PowerShell engine intrinsics.</param>
		/// <param name="inputData">The input value to transform.</param>
		/// <returns>The identity reference the input object represents.</returns>
		/// <exception cref="InvalidOperationException">Thrown if the input object was valid but did not contain the required data.</exception>
		/// <exception cref="ArgumentException">Thrown if the input object is not supported for transformation.</exception>
		/// <exception cref="ArgumentNullException">Thrown if the input data is null.</exception>
		public override object Transform(EngineIntrinsics engineIntrinsics, object? inputData)
		{
			var baseObj = (inputData is PSObject psObj ? psObj.BaseObject : inputData) ?? throw new ArgumentNullException(paramName: nameof(inputData), "Cannot transform null to IdentityReference.");
			if (baseObj is IdentityReference identity)
			{
				return identity;
			}
			if (baseObj is WellKnownSidType wellKnownSidType)
			{
				return new SecurityIdentifier(wellKnownSidType, domainSid: null);
			}
			if (baseObj is WindowsIdentity windowsIdentity)
			{
				return windowsIdentity.User ?? throw new InvalidOperationException("The given WindowsIdentity did not provide the required user identity.");
			}
			if (baseObj is string str && TryParseIdentityReference(str, out var strIdentity))
			{
				return strIdentity!;
			}
			if (TryConvertPowerShellCommandObject(baseObj, out var pwshCommandSid))
			{
				return pwshCommandSid!;
			}
			throw new ArgumentException("Input data must be of type IdentityReference, WindowsIdentity, LocalPrincipal, WellKnownSidType or a string representing any of those types.", nameof(inputData));
		}

		/// <summary>
		/// Try to parse string into an <see cref="IdentityReference"/>.
		/// </summary>
		/// <param name="identityString">The string representing the IdentityReference.</param>
		/// <param name="identity">The parsed IdentityReference.</param>
		/// <returns>True if parsing was successful, otherwise false.</returns>
		private static bool TryParseIdentityReference(string identityString, out IdentityReference? identity)
		{
			if (string.IsNullOrWhiteSpace(identityString))
			{
				identity = null;
				return false;
			}
			if (Enum.TryParse(identityString, ignoreCase: true, out WellKnownSidType wellKnownSidType))
			{
				identity = new SecurityIdentifier(wellKnownSidType, domainSid: null);
				return true;
			}
			if (TryParseSid(identityString, out var sid))
			{
				identity = sid;
				return true;
			}
			if (TryParseNTAccount(identityString, out var ntAccount))
			{
				identity = ntAccount;
				return true;
			}
			identity = null;
			return false;
		}

		/// <summary>
		/// Try to parse string into a <see cref="SecurityIdentifier"/>.
		/// </summary>
		/// <param name="identityString">The string representing the SecrutiyIdentifier.</param>
		/// <param name="identity">The parsed SecrutiyIdentifier.</param>
		/// <returns>True if parsing was successful, otherwise false.</returns>
		private static bool TryParseSid(string identityString, out SecurityIdentifier? identity)
		{
			try
			{
				identity = new SecurityIdentifier(identityString);
				return true;
			}
			catch (ArgumentException)
			{
				identity = null;
				return false;
			}
		}

		/// <summary>
		/// Try to parse string into a <see cref="NTAccount"/>.
		/// </summary>
		/// <param name="identityString">The string representing the NTAccount.</param>
		/// <param name="identity">The parsed NTAccount.</param>
		/// <returns>True if parsing was successful, otherwise false.</returns>
		private static bool TryParseNTAccount(string identityString, out NTAccount? identity)
		{
			try
			{
				identity = new NTAccount(identityString);
				return true;
			}
			catch (IdentityNotMappedException)
			{
				identity = null;
				return false;
			}
		}

		/// <summary>
		/// Try to extract the SID from a LocalPrincipal type using reflection. The LocalPrincipal type is used within the Microsoft.PowerShell.LocalAccounts module.
		/// </summary>
		/// <param name="identityObject">The object to analyse.</param>
		/// <param name="identity">The parsed SecrutiyIdentifier.</param>
		/// <returns>True if extraction was successful, otherwise false.</returns>
		private static bool TryConvertPowerShellCommandObject(object identityObject, out SecurityIdentifier? identity)
		{
			Type objectType = identityObject.GetType();
			if (!string.Equals(objectType.Namespace, "Microsoft.PowerShell.Commands", StringComparison.Ordinal))
			{
				identity = null;
				return false;
			}
			if (string.Equals(objectType.Name, "LocalPrincipal", StringComparison.Ordinal)
				&& objectType.GetProperty("SID", typeof(SecurityIdentifier)) is PropertyInfo directProperty
				&& directProperty.GetValue(identityObject) is SecurityIdentifier directSid)
			{
				identity = directSid;
				return true;
			}
			if (objectType.BaseType is Type baseType
				&& string.Equals(baseType.Name, "LocalPrincipal", StringComparison.Ordinal)
				&& objectType.GetProperty("SID", typeof(SecurityIdentifier)) is PropertyInfo baseProperty
				&& baseProperty.GetValue(identityObject) is SecurityIdentifier baseSid)
			{
				identity = baseSid;
				return true;
			}
			identity = null;
			return false;
		}
	}
}
