
using System;
using System.Collections;
using PSADTNXT.Application;

namespace PSADTNXT.Deployment
{
	public sealed record NxtRequirement
	{
		public NxtApplicationCriteria Criteria { get; }

		public RequirementState DesiredState { get; }

		public RequirementConflictAction OnConflict { get; }

		public string ErrorMessage { get; }

		public NxtRequirement(
			NxtApplicationCriteria criteria,
			RequirementState desiredState = RequirementState.Present,
			RequirementConflictAction conflictAction = RequirementConflictAction.Fail,
			string errorMessage = ""
		)
		{
			Criteria = criteria;
			DesiredState = desiredState;
			OnConflict = conflictAction;
			ErrorMessage = !string.IsNullOrWhiteSpace(errorMessage)
				? errorMessage
				: $"The desired [{Criteria.Store}] application was not [{DesiredState}] as required by this deployment.";
		}

		public static implicit operator NxtRequirement(Hashtable hashtable)
		{
			return FromHashtable(hashtable);
		}

		public static NxtRequirement FromHashtable(Hashtable hashtable)
		{
			if (hashtable == null)
			{
				throw new ArgumentNullException(nameof(hashtable));
			}

			var criteriaHashtable = hashtable.ContainsKey("Criteria") && hashtable["Criteria"] is Hashtable criteriaTable
				? criteriaTable
				: throw new ArgumentException("Missing or invalid 'Criteria' hashtable in the provided hashtable.");
			var criteria = NxtApplicationCriteria.FromHashtable(criteriaHashtable);

			var desiredState = hashtable.ContainsKey("DesiredState")
				? Enum.TryParse<RequirementState>(hashtable["DesiredState"]?.ToString(), true, out var state) ? state : throw new ArgumentException($"Invalid value for DesiredState: {hashtable["DesiredState"]}")
				: RequirementState.Present;

			var conflictAction = hashtable.ContainsKey("OnConflict")
				? Enum.TryParse<RequirementConflictAction>(hashtable["OnConflict"]?.ToString(), true, out var action) ? action : throw new ArgumentException($"Invalid value for OnConflict: {hashtable["OnConflict"]}")
				: RequirementConflictAction.Fail;

			var errorMessage = hashtable.ContainsKey("ErrorMessage")
				? hashtable["ErrorMessage"] is string message ? message : throw new ArgumentException($"Invalid value for ErrorMessage: {hashtable["ErrorMessage"]}")
				: string.Empty;

			return new NxtRequirement(criteria, desiredState, conflictAction, errorMessage);
		}

		public override string ToString()
		{
			return $"{Criteria.Store} {DesiredState.ToString().ToLower()} requirement";
		}
	}
}
