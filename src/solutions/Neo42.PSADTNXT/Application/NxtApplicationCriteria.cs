using System;
using System.Collections;
using System.Management.Automation;

namespace PSADTNXT.Application
{
	public sealed record NxtApplicationCriteria
	{
		public ApplicationStore Store { get; }

		public string? Identifier { get; }

		public ScriptBlock? Filter { get; }

		public NxtApplicationCriteria(
			ApplicationStore store,
			string identifier
		)
		{
			AssertNotEmpty(identifier, nameof(identifier));

			Store = store;
			Identifier = identifier;
		}

		public NxtApplicationCriteria(
			ApplicationStore store,
			ScriptBlock filter
		)
		{
			AssertNotEmpty(filter?.ToString(), nameof(filter));

			Store = store;
			Filter = filter;
		}

		public NxtApplicationCriteria(
			ApplicationStore store,
			string identifier,
			ScriptBlock filter
		)
		{
			AssertNotEmpty(identifier, nameof(identifier));
			AssertNotEmpty(filter?.ToString(), nameof(filter));

			Store = store;
			Identifier = identifier;
			Filter = filter;
		}

		public static implicit operator NxtApplicationCriteria(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtApplicationCriteria FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var store = hashtable.ContainsKey("Store")
				? Enum.TryParse<ApplicationStore>(hashtable["Store"]?.ToString(), true, out var parsedStore) ? parsedStore : throw new ArgumentException("The hashtable must contain a 'Store' key with a valid value.", nameof(hashtable))
				: ApplicationStore.ARP;

			string? identifier = null;
			if (hashtable.ContainsKey("Identifier"))
			{
				if (hashtable["Identifier"] is string id)
				{
					AssertNotEmpty(id, nameof(identifier));
					identifier = id;
				}
				else
				{
					throw new ArgumentException($"Invalid value for Identifier: {hashtable["Identifier"]}");
				}
			}

			ScriptBlock? filter = null;
			if (hashtable.ContainsKey("Filter"))
			{
				if (hashtable["Filter"] is ScriptBlock sb)
				{
					AssertNotEmpty(sb.ToString(), nameof(filter));
					filter = sb;
				}
				else
				{
					throw new ArgumentException($"Invalid value for Filter: {hashtable["Filter"]}");
				}
			}

			if (identifier is null && filter is null)
			{
				throw new ArgumentException("The hashtable must contain at least an 'Identifier' or a 'Filter' key.", nameof(hashtable));
			}

			if (identifier is not null && filter is not null)
			{
				return new NxtApplicationCriteria(store, identifier, filter);
			}
			else if (identifier is not null)
			{
				return new NxtApplicationCriteria(store, identifier);
			}
			else // filter is not null
			{
				return new NxtApplicationCriteria(store, filter!);
			}
		}

		public override string ToString()
		{
			return $"{Store} Application Criteria";
		}

		private static void AssertNotEmpty(string? value, string paramName)
		{
			if (string.IsNullOrWhiteSpace(value))
			{
				throw new ArgumentException("Value cannot be null or whitespace.", paramName);
			}
		}
	}
}
