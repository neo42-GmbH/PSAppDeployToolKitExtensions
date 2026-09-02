
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

		public override string ToString()
		{
			return $"{Criteria.Store} {DesiredState.ToString().ToLower()} requirement";
		}
	}
}
