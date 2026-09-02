using System;
using System.Collections;
using System.Management.Automation;

namespace PSADTNXT.Application
{
	public sealed class NxtApplicationCriteria
	{
		public ApplicationStore Store { get; }

		public string? Identifier { get; }

		public ScriptBlock? Filter { get; }

		public override string ToString()
		{
			return $"{Store} Application Criteria";
		}

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

		public NxtApplicationCriteria(Hashtable hashtable)
		{
			if (!hashtable.ContainsKey("Store") || !Enum.TryParse<ApplicationStore>(hashtable["Store"]?.ToString(), true, out var store))
			{
				throw new ArgumentException("The hashtable must contain a 'Store' key with a valid value.", nameof(hashtable));
			}
			Store = store;

			Identifier = hashtable["Identifier"] as string;
			Filter = hashtable["Filter"] as ScriptBlock;

			if (Identifier is null && Filter is null)
			{
				throw new ArgumentException("The hashtable must contain at least an 'Identifier' or a 'Filter' key.", nameof(hashtable));
			}

			if (Identifier is not null)
			{
				AssertNotEmpty(Identifier, nameof(Identifier));
			}

			if (Filter is not null)
			{
				AssertNotEmpty(Filter.ToString(), nameof(Filter));
			}
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
