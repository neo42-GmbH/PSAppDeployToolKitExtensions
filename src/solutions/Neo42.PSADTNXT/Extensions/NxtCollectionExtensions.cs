using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace PSADTNXT.Extensions
{
	public static class NxtCollectionExtensions
	{
		/// <summary>
		/// A implementation of the LINQ DistinctBy method.
		/// </summary>
		/// <typeparam name="T">The type of the elements in the collection.</typeparam>
		/// <typeparam name="TU">The type of the key to group by.</typeparam>
		/// <param name="input">The collection to filter.</param>
		/// <param name="keySelector">A function to extract the key from each element.</param>
		/// <returns>A collection of distinct elements based on the key.</returns>
		public static IEnumerable<T> DistinctBy<T, TU>(this IEnumerable<T> input, Func<T, TU> keySelector)
		{
			var set = new HashSet<TU>();
			foreach (var item in input)
			{
				if (set.Add(keySelector(item)))
				{
					yield return item;
				}
			}
		}

		/// <summary>
		/// Deep-merges two <see cref="IDictionary"/> objects.
		/// </summary>
		/// <param name="baseTable">The base table to merge into.</param>
		/// <param name="targetTable">The table to merge into the base table.</param>
		/// <param name="overwrite">Indicates whether values in the base table should be overwritten by values in the merge table.</param>
		/// <returns>The merged <see cref="IDictionary"/>.</returns>
		/// <remarks>
		/// The current implementation does not handle collections within the dictionaries.
		/// Collections are simply overwritten if the key exists in both dictionaries.
		/// </remarks>
		public static IDictionary Merge(this IDictionary baseTable, IDictionary targetTable, bool overwrite = false)
		{
			foreach (DictionaryEntry entry in targetTable)
			{
				if (baseTable.Contains(entry.Key))
				{
					if (baseTable[entry.Key] is IDictionary subDict && entry.Value is IDictionary targetSubDict)
					{
						baseTable[entry.Key] = subDict.Merge(targetSubDict, overwrite);
					}
					else if (overwrite)
					{
						baseTable[entry.Key] = entry.Value;
					}
				}
				else
				{
					baseTable.Add(entry.Key, entry.Value);
				}
			}
			return baseTable;
		}

		/// <summary>
		/// Checks if every key of the given dictionary matches exactly one property of the given type.
		/// </summary>
		/// <typeparam name="T">The type whose properties the keys are matched against.</typeparam>
		/// <param name="dict">The dictionary whose keys to check.</param>
		/// <param name="errorKeys">The keys that are not a string, match no or multiple properties, or match a property already matched by another key. Empty if all keys match.</param>
		/// <param name="caseSensitive">If true, keys are matched case sensitive.</param>
		/// <param name="flags">The binding flags used to look up the properties.</param>
		/// <returns>True if every key matches exactly one property, otherwise false.</returns>
#pragma warning disable CA1021
		public static bool MatchesProperties<T>(this IDictionary dict, out string[] errorKeys, bool caseSensitive = false, BindingFlags flags = BindingFlags.Public | BindingFlags.Instance)
#pragma warning restore CA1021
		{
			var properties = typeof(T).GetProperties(flags).Where(p => p.GetIndexParameters().Length == 0).Select(p => p.Name).ToArray();
			var comparer = caseSensitive ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase;
			var matchedProperties = new HashSet<string>(StringComparer.Ordinal);
			var invalidKeys = new List<string>();

			foreach (var key in dict.Keys)
			{
				if (key is not string name)
				{
					invalidKeys.Add($"[non-string key: {key?.GetType().FullName ?? "null"}]");
					continue;
				}

				var matches = properties.Where(p => comparer.Equals(p, name)).ToArray();
				if (matches.Length != 1 || !matchedProperties.Add(matches[0]))
				{
					invalidKeys.Add(name);
				}
			}

			errorKeys = [.. invalidKeys];
			return errorKeys.Length == 0;
		}
	}
}
