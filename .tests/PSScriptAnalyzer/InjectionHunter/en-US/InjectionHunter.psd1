ConvertFrom-StringData @'
# English strings
MeasureInvokeExpression = Possible script injection risk via the Invoke-Expression cmdlet. Untrusted input can cause arbitrary PowerShell expressions to be run. Variables may be used directly for dynamic parameter arguments, splatting can be used for dynamic parameter names, and the invocation operator can be used for dynamic command names. If content escaping is truly needed, PowerShell has several valid quote characters, so  [System.Management.Automation.Language.CodeGeneration]::Escape* should be used.
MeasureAddType = Possible code injection risk via the Add-Type cmdlet. Untrusted input can cause arbitrary Win32 code to be run.
MeasureDangerousMethod = Possible script injection risk via the a dangerous method. Untrusted input can cause arbitrary PowerShell expressions to be run. The PowerShell.AddCommand().AddParameter() APIs should be used instead.
MeasureCommandInjection = Possible command injection risk via calling cmd.exe or powershell.exe. Untrusted input can cause arbitrary commands to be run. Input should be provided as variable input directly (such as 'cmd /c ping `$destination', rather than within an expandable string.
MeasureForeachObjectInjection = Possible property access injection via Foreach-Object. Untrusted input can cause arbitrary properties /methods to be accessed:
MeasurePropertyInjection = Possible property access injection via dynamic member access. Untrusted input can cause arbitrary static properties to be accessed:
MeasureMethodInjection = Possible property access injection via dynamic member access. Untrusted input can cause arbitrary static properties to be accessed:
MeasureUnsafeEscaping = Possible unsafe use of input escaping. Variables may be used directly for dynamic parameter arguments, splatting can be used for dynamic parameter names, and the invocation operator can be used for dynamic command names. If content escaping is truly needed, PowerShell has several valid quote characters, so  [System.Management.Automation.Language.CodeGeneration]::Escape* should be used instead.
'@
