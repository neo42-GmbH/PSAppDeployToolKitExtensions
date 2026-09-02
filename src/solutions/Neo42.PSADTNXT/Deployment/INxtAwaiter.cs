using System;

namespace PSADTNXT.Deployment
{
	public interface INxtAwaiter
	{
		bool Exists { get; }

		TimeSpan Timeout { get; }

		bool Evaluate();
	}
}
