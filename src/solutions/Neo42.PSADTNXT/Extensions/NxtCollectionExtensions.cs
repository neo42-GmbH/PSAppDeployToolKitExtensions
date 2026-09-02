using System;
using System.Collections;
using System.Collections.Generic;

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
	}
}
