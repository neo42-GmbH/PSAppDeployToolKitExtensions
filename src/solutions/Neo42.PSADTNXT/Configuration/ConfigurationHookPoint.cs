namespace PSADTNXT.Configuration
{
	/// <summary>
	/// Defines the hook points during the session configuration process, before a deployment session is opened.
	/// Callbacks for these hook points are registered with Add-NXTConfigurationCallback.
	/// </summary>
	public enum ConfigurationHookPoint
	{
		/// <summary>
		/// Invoked after the Setup.cfg files have been merged and before the toolkit overrides are applied and the package configuration is constructed.
		/// </summary>
		SetupCfg
	}
}
