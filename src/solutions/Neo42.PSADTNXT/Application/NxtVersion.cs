using System;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Text.RegularExpressions;
using PSADTNXT.Extensions;

namespace PSADTNXT.Application
{
	/// <summary>
	/// A version class that supports lazy version parsing and comparison.
	/// It can handle several version formats, including semantic versions.
	/// </summary>
	/// <remarks>
	/// Tested formats:
	/// - 1.0
	/// - 1.0.0-alpha+build.123
	/// - 1.0.0beta
	/// - v1
	/// - dev-2025-03
	/// - 1.5.2042 RC 1
	/// - hallo 2025
	[Serializable]
	public sealed class NxtVersion : IComparable, ISerializable, ICloneable
	{
		public int Major { get; }

		public int Minor { get; } = -1;

		public int Patch { get; } = -1;

		public int Revision { get; } = -1;

		public string PreRelease { get; } = string.Empty;

		public string Build { get; } = string.Empty;

		public bool IsPreRelease { get; }

		private static readonly Lazy<Regex> _strictVersionConstructRegex = new(() => new Regex(
			@"(?<Major>\d{1,9})(?:\.(?<Minor>\d{1,9}))(?:\.(?<Patch>\d{1,9}))?(?:\.(?<Revision>\d{1,9}))?",
			RegexOptions.Compiled
		));

		private static readonly Lazy<Regex> _looseVersionConstructRegex = new(() => new Regex(
			@"(?<Major>\d{1,9})(?<Separator>[\.\-_,])(?<Minor>\d{1,9})(?:\k<Separator>(?<Patch>\d{1,9}))?(?:\k<Separator>(?<Revision>\d{1,9}))?",
			RegexOptions.Compiled
		));

		private static readonly Lazy<Regex> _numberSequenceRegex = new(() => new Regex(
			@"(?<Major>\d+)",
			RegexOptions.Compiled
		));

		private static readonly Lazy<Regex> _versionSuffixRegex = new(() => new Regex(
			@"^(?:-(?<PreRelease>[^\+\n]+(?:\+$)?))?(?:\+?(?<Build>[^\n]*))?",
			RegexOptions.Compiled
		));

		private static readonly char[] _trimChars = [' ', '-', '_', ',', '.', ':', ';', '/', '\\', '\n'];

		/// <summary>
		/// The version construct regexes accept at most nine digits per part.
		/// </summary>
		private const int MAX_VERSION_PART = 999_999_999;

		private readonly string _versionString;

		public NxtVersion(string version)
		{
			if (string.IsNullOrWhiteSpace(version))
			{
				throw new ArgumentNullException(nameof(version), "Version string cannot be null or empty.");
			}

			_versionString = version;

			var versionMatch = new Lazy<Regex>[] { _strictVersionConstructRegex, _looseVersionConstructRegex, _numberSequenceRegex }
				.Select(regex => regex.Value.Match(version))
				.FirstOrDefault(match => match.Success)
				?? throw new InvalidOperationException($"The given string {version} did not translate to a parsable version format.");

			Major = int.Parse(versionMatch.Groups["Major"].Value);

			if (versionMatch.Groups["Minor"].Success)
			{
				Minor = int.Parse(versionMatch.Groups["Minor"].Value);
			}

			if (versionMatch.Groups["Patch"].Success)
			{
				Patch = int.Parse(versionMatch.Groups["Patch"].Value);
			}

			if (versionMatch.Groups["Revision"].Success)
			{
				Revision = int.Parse(versionMatch.Groups["Revision"].Value);
			}

			var versionInfo = string.Empty;
			var isSuffix = true;
			if (versionMatch.Index + versionMatch.Length < version.Length)
			{
				versionInfo = version.Substring(versionMatch.Index + versionMatch.Length).Trim();
			}
			else if (versionMatch.Index > 0)
			{
				versionInfo = version.Substring(0, versionMatch.Index).Trim();
				isSuffix = false;
			}

			if (string.IsNullOrWhiteSpace(versionInfo) || (!isSuffix && versionInfo == "v"))
			{
				return;
			}

			if (isSuffix)
			{
				var suffixMatch = _versionSuffixRegex.Value.Match(versionInfo);

				IsPreRelease = suffixMatch.Groups["PreRelease"].Success;
				if (IsPreRelease)
				{
					PreRelease = CleanVersionLabel(suffixMatch.Groups["PreRelease"].Value);
				}

				if (suffixMatch.Groups["Build"].Success)
				{
					Build = CleanVersionLabel(suffixMatch.Groups["Build"].Value);
				}
			}
			else
			{
				Build = CleanVersionLabel(versionInfo);
			}
		}

		public NxtVersion(Version version)
		{
			if (version == null)
			{
				throw new ArgumentNullException(nameof(version));
			}

			_versionString = version.ToString();

			Major = version.Major;
			Minor = version.Minor;
			Patch = version.Build;
			Revision = version.Revision;
		}

		public NxtVersion(int major, int minor = -1, int patch = -1, int revision = -1, string preRelease = "", string build = "")
		{
			if (major is < 0 or > MAX_VERSION_PART)
			{
				throw new ArgumentOutOfRangeException(nameof(major), "Major version must be a non-negative integer.");
			}

			if (minor is < -1 or > MAX_VERSION_PART)
			{
				throw new ArgumentOutOfRangeException(nameof(minor));
			}

			if (patch < -1 || patch > MAX_VERSION_PART || (patch != -1 && minor == -1))
			{
				throw new ArgumentOutOfRangeException(nameof(patch));
			}

			if (revision < -1 || revision > MAX_VERSION_PART || (revision != -1 && patch == -1))
			{
				throw new ArgumentOutOfRangeException(nameof(revision));
			}

			preRelease = string.IsNullOrWhiteSpace(preRelease) ? string.Empty : preRelease;
			build = string.IsNullOrWhiteSpace(build) ? string.Empty : build;

			if (preRelease.Contains("+"))
			{
				throw new ArgumentException("Pre-release must not contain '+' as it separates the build.", nameof(preRelease));
			}

			ThrowIfAlteredByParser(preRelease, nameof(preRelease));
			ThrowIfAlteredByParser(build, nameof(build));

			var versionSb = new StringBuilder($"{major}");
			if (minor != -1)
			{
				_ = versionSb.Append($".{minor}");
			}

			if (patch != -1)
			{
				_ = versionSb.Append($".{patch}");
			}

			if (revision != -1)
			{
				_ = versionSb.Append($".{revision}");
			}

			if (!string.IsNullOrWhiteSpace(preRelease))
			{
				_ = versionSb.Append($"-{preRelease}");
			}

			if (!string.IsNullOrWhiteSpace(build))
			{
				_ = versionSb.Append($"+{build}");
			}

			_versionString = versionSb.ToString();

			// Without a minor version only the number sequence regex must match, otherwise digits
			// in the pre-release or build would be picked up as version parts (e.g. 5-1 => 5.1).
			if (minor == -1
				&& (_strictVersionConstructRegex.Value.IsMatch(_versionString) || _looseVersionConstructRegex.Value.IsMatch(_versionString)))
			{
				throw new ArgumentException($"Without a minor version, pre-release and build must not look like a version number: '{_versionString}'.");
			}

			Major = major;
			Minor = minor;
			Patch = patch;
			Revision = revision;
			PreRelease = preRelease;
			IsPreRelease = !string.IsNullOrWhiteSpace(PreRelease);
			Build = build;
		}

		public static implicit operator Version(NxtVersion version)
		{
			return version.ToVersion();
		}

		public Version ToVersion()
		{
			var minor = Minor == -1 ? 0 : Minor;
			return Patch == -1
				? new Version(Major, minor)
				: Revision == -1
					? new Version(Major, minor, Patch)
					: new Version(Major, minor, Patch, Revision);
		}

		public static implicit operator NxtVersion(Version version)
		{
			return FromVersion(version);
		}

		public static NxtVersion FromVersion(Version version)
		{
			return new NxtVersion(version);
		}

		public static implicit operator NxtVersion(string version)
		{
			return FromString(version);
		}

		public static NxtVersion FromString(string version)
		{
			return new NxtVersion(version);
		}

		public int CompareTo(object? other)
		{
			if (other == null)
			{
				return 1;
			}

			if (other is NxtVersion version)
			{
				return CompareTo(version);
			}

			if (other is Version versionObj)
			{
				return CompareTo(new NxtVersion(versionObj));
			}

			if (other is string strVersion)
			{
				return CompareTo(new NxtVersion(strVersion));
			}

			throw new ArgumentException($"Object is not a valid version: {other.GetType().Name}", nameof(other));
		}

		/// <summary>
		/// Returns the original string representation of the version that was used to create this instance.
		/// </summary>
		public override string ToString()
		{
			return _versionString;
		}

		/// <summary>
		/// Deserialization constructor. Only the original version string is persisted,
		/// all other parts are derived from it by the string constructor and its validation.
		/// </summary>
		private NxtVersion(SerializationInfo info, StreamingContext context)
			: this(info.GetString(nameof(_versionString))!)
		{
		}

		public void GetObjectData(SerializationInfo info, StreamingContext context)
		{
			info.AddValue(nameof(_versionString), _versionString);
		}

		/// <summary>
		/// Creates a deep copy of the current version instance.
		/// </summary>
		/// <returns>A new instance of <see cref="NxtVersion"/> with the same values as the current instance.</returns>
		public object Clone()
		{
			return new NxtVersion(_versionString);
		}

		/// <summary>
		/// Tries to parse a version string into a <see cref="NxtVersion"/>.
		/// </summary>
		/// <param name="version">The version string to parse.</param>
		/// <param name="result">The parsed <see cref="NxtVersion"/> if successful; otherwise, a default version.</param>
		/// <returns>true if the parsing was successful; otherwise, false.</returns>
		public static bool TryParse(string? version, out NxtVersion result)
		{
			try
			{
				if (string.IsNullOrEmpty(version))
				{
					throw new ArgumentNullException(nameof(version));
				}

				result = new NxtVersion(version!);
				return true;
			}
			catch
			{
				result = new NxtVersion(0);
				return false;
			}
		}

		/// <summary>
		/// Returns the hash code for this version.
		/// </summary>
		/// <returns>A 32-bit signed integer hash code.</returns>
		public override int GetHashCode()
		{
			unchecked
			{
				var hash = 17;
				hash = (hash * 23) + Major.GetHashCode();
				hash = (hash * 23) + Minor.GetHashCode();
				hash = (hash * 23) + Patch.GetHashCode();
				hash = (hash * 23) + Revision.GetHashCode();
				hash = (hash * 23) + (PreRelease?.ToLower().GetHashCode() ?? 0);
				hash = (hash * 23) + (Build?.ToLower().GetHashCode() ?? 0);
				return hash;
			}
		}

		/// <summary>
		/// Determines whether the specified object is equal to the current version.
		/// </summary>
		/// <param name="obj">The object to compare with the current version.</param>
		/// <returns>true if the specified object is equal to the current version; otherwise, false.</returns>
		public override bool Equals(object? obj)
		{
			return CompareTo(obj) == 0;
		}

		public static bool operator ==(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) == 0;
		}

		public static bool operator !=(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) != 0;
		}

		public static bool operator <(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) < 0;
		}

		public static bool operator >(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) > 0;
		}

		public static bool operator <=(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) <= 0;
		}

		public static bool operator >=(NxtVersion left, NxtVersion right)
		{
			return left.CompareTo(right) >= 0;
		}

		public static bool operator ==(NxtVersion left, Version right)
		{
			return left.CompareTo(right) == 0;
		}

		public static bool operator !=(NxtVersion left, Version right)
		{
			return left.CompareTo(right) != 0;
		}

		public static bool operator <(NxtVersion left, Version right)
		{
			return left.CompareTo(right) < 0;
		}

		public static bool operator >(NxtVersion left, Version right)
		{
			return left.CompareTo(right) > 0;
		}

		public static bool operator <=(NxtVersion left, Version right)
		{
			return left.CompareTo(right) <= 0;
		}

		public static bool operator >=(NxtVersion left, Version right)
		{
			return left.CompareTo(right) >= 0;
		}

		private int CompareTo(NxtVersion other)
		{
			int CompareVersionPart(int left, int right)
			{
				// Treat -1 as 0 for comparison purposes
				var leftValue = left == -1 ? 0 : left;
				var rightValue = right == -1 ? 0 : right;
				return leftValue.CompareTo(rightValue);
			}

			var result = CompareVersionPart(Major, other.Major);
			if (result != 0)
			{
				return result;
			}

			result = CompareVersionPart(Minor, other.Minor);
			if (result != 0)
			{
				return result;
			}

			result = CompareVersionPart(Patch, other.Patch);
			if (result != 0)
			{
				return result;
			}

			result = CompareVersionPart(Revision, other.Revision);
			if (result != 0)
			{
				return result;
			}

			if (!IsPreRelease && other.IsPreRelease)
			{
				return -1;
			}

			if (IsPreRelease && !other.IsPreRelease)
			{
				return 1;
			}

			if (IsPreRelease && other.IsPreRelease)
			{
				// Allow fallback to build if prerelease is equal
				var releaseResult = PreRelease.CompareTo(other.PreRelease);
				if (releaseResult != 0)
				{
					return releaseResult;
				}
			}

			if (Build is null && other.Build is not null)
			{
				return -1;
			}

			if (Build is not null && other.Build is null)
			{
				return 1;
			}

			if (Build is not null && other.Build is not null)
			{
				return Build.CompareTo(other.Build);
			}

			return 0;
		}

		/// <summary>
		/// Removes enclosing parentheses and separator characters from a pre-release or build value.
		/// </summary>
		private static string CleanVersionLabel(string value)
		{
			return value.RemoveParentheses().Trim(_trimChars);
		}

		/// <summary>
		/// Ensures a pre-release or build value is returned unchanged when the version string is parsed again.
		/// </summary>
		private static void ThrowIfAlteredByParser(string value, string paramName)
		{
			// The parser trims the whitespace of the whole suffix before cleaning the labels
			if (value != CleanVersionLabel(value.Trim()))
			{
				throw new ArgumentException($"'{value}' must not contain line breaks or start or end with whitespace, enclosing parentheses or any of '{string.Join(string.Empty, _trimChars)}'.", paramName);
			}
		}
	}
}
