% Functions in PSAppDeployToolkit.Neo42.Extensions module

## Add-NXTContent

Replaces `Add-Content` with neo42 encoding handling for files.

### SYNTAX

```PowerShell
# ParameterSet Path
Add-NXTContent
    [-Path] <string[]>
    [-Value] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-PassThru]
    [-NoNewLine]
    [-Force]
    [-Encoding <Encoding>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Add-NXTContent
    [-Value] <string[]>
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-PassThru]
    [-NoNewLine]
    [-Force]
    [-Encoding <Encoding>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

It's use is limited to only files and it will determine the encoding of the file and use that if no encoding is specified.
Should the detection fail, or if the file doesn't exist, it will use the encoding defined in the DefaultEncoding parameter.
Important note: If the file exists and the encoding is specified, the encoding will not be updated. Only the new content will be written with the specified encoding.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World'
```

Adds the content 'Hello World' to the file 'C:\Temp\test.txt'.

#### Example 2

```PowerShell
Add-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World' -Encoding UTF8
```

Adds the content 'Hello World' to the file 'C:\Temp\test.txt' using the UTF8 encoding. If the file exists, only the new content will be written with the specified encoding.

### INPUTS

System.String[] - The content to add to the file(s).
System.IO.FileInfo[] - The file(s) to add content to.

### OUTPUTS

System.String[] - The content that was added to the file(s) if the `-PassThru` parameter is specified.

### PARAMETERS

#### -Path

The path to the file(s) to add content to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to add content to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Value

The content to add to the file(s).

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -PassThru

Returns the content added to the file(s) if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoNewLine

Do not append a newline character to the content.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created. If the file exists, the encoding will not be updated.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Add-NXTDeploymentCallback

Add a custom hook that is run after a specific custom function.

### SYNTAX

```PowerShell
Add-NXTDeploymentCallback
    [-Callback] <CommandInfo[]>
    [[-HookPoint] <DeploymentHookPoint[]>]
    [-Prepend]
    [<CommonParameters>]
```

### DESCRIPTION

The Add-NXTDeploymentCallback function adds a custom hook to the deployment session that is executed after the specified deployment hook point.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')
```

This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Callback

The command information object representing the custom function to be executed as a hook.

|Property|Value|
|:---|:---|
|Type:|CommandInfo[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -HookPoint

The name of the deployment hook point after which the custom hook should be executed.
If this parameter is omitted, the name of the callback will be used to determine the hook point.

|Property|Value|
|:---|:---|
|Type:|DeploymentHookPoint[]|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Prepend

Add the hook to the to of the list.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Add-NXTFolderPermission

Adds access control permissions on a specified, existing folder without removing existing permissions.

### SYNTAX

```PowerShell
# ParameterSet Path
Add-NXTFolderPermission
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Recurse]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Add-NXTFolderPermission
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Recurse]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

The function allows granular control over the access permissions of a specified folder.
It can assign specific permission levels (e.g., Full Control, Modify, Write, Read & Execute) to identity references (SID, user name or group name).
The function also provides options to set the owner, manage custom directory security settings, and control the inheritance of permissions.
It is capable of applying these settings to both the target folder and its sub-folders.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'
```

Add permissions to folder 'C:\Temp\MyFolder' granting full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone'.

### INPUTS

System.String[] - The path to the folder(s) to set permissions on.

System.IO.DirectoryInfo[] - The folder(s) to set permissions on.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the folder(s) to add permissions to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the folder(s) to add permissions to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -FullControl

The user(s) or group(s) to grant full control permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Write

The user(s) or group(s) to grant write permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Modify

The user(s) or group(s) to grant modify permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ReadAndExecute

The user(s) or group(s) to grant read and execute permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Recurse

Specifies that the permissions should be applied to all sub-folders of the specified folder.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Add-NXTPathVariable

Extends the PATH environment variable.

### SYNTAX

```PowerShell
Add-NXTPathVariable
    [-Path] <string[]>
    [-Prepend]
    [-Target <EnvironmentVariableTarget>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Extends the PATH environment variable of a specified target with the given path(s).
If the path already exists, it will not be added again. Empty values will be removed.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTPathVariable -Path 'C:\Program Files\Example\bin'
```

Adds the path 'C:\Program Files\Example\bin' to the machine PATH variable.

#### Example 2

```PowerShell
Add-NXTPathVariable -Path 'C:\Program Files\Example\bin' -Prepend -Target Process
```

Adds the path 'C:\Program Files\Example\bin' to the process PATH variable at the beginning.

### INPUTS

System.String[] - The path(s) to add to the PATH variable.
System.IO.DirectoryInfo[] - The path(s) to add to the PATH variable.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path(s) to add to the PATH variable.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Prepend

When specified, the path will be added at the beginning of the PATH variable.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Target

Determines the scope of the PATH variable to be modified.

|Property|Value|
|:---|:---|
|Type:|EnvironmentVariableTarget|
|Enum values:|Process, User, Machine|
|Position:|Named|
|Default value:|Machine|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Add-NXTXmlNode

Adds a new node to an existing xml node.

### SYNTAX

```PowerShell
# ParameterSet Path
Add-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    -Name <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Add-NXTXmlNode
    -LiteralPath <string[]>
    -XPath <string>
    -Name <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
Add-NXTXmlNode
    -XPath <string>
    -Name <string>
    [-InputObject <XmlNode[]>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Adds a new node to an existing xml node. The node is added at the specified XPath location.
The XPath must point to a single node. The new node will be added as a child node of the specified node.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent' -Name 'child' -Attributes @{ attr1 = 'value1'; attr2 = 'value2' } -InnerText 'Hello World'
```

Adds a new node 'child' to the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent'.

### INPUTS

System.Xml.XmlNode[] - The XML node(s) or XML document(s) to add the new node to.

System.IO.FileInfo[] - The XML file(s) to add the new node to.

### OUTPUTS

System.Xml.XmlNode[] - The XML node(s) or document(s) that were modified if the `-PassThru` parameter is specified.

### PARAMETERS

#### -Path

The path to the XML file(s) to add the node to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to add the node to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created. If the file exists, the encoding will not be updated.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to add the new node to.

|Property|Value|
|:---|:---|
|Type:|XmlNode[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to add the new node to.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Name

The name of the new node to add.
The name can contain a namespace prefix (e.g. 'ns:nodeName') if the node is in a namespace. The namespace prefix must be defined in the XML document.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Attributes

A hashtable of attributes to set on the new node.
The keys can contain a namespace prefix (e.g. 'ns:attrName') if the attribute is in a namespace. The namespace prefix must be defined in the XML document.

|Property|Value|
|:---|:---|
|Type:|Hashtable|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InnerText

The inner text to set on the new node.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Returns the XML document if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Clear-NXTDeploymentCallback

Clears all custom hooks.

### SYNTAX

```PowerShell
Clear-NXTDeploymentCallback
    [-HookPoint] <DeploymentHookPoint[]>
    [<CommonParameters>]
```

### DESCRIPTION

The Clear-NXTDeploymentCallback function removes a custom hook from the deployment session that was previously added with Add-NXTDeploymentCallback.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')
```

This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -HookPoint

The name of the deployment hook point after which the custom hook should be executed.

|Property|Value|
|:---|:---|
|Type:|DeploymentHookPoint[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Compare-NXTVersion

Compare two versions with extended support for different version formats.

### SYNTAX

```PowerShell
Compare-NXTVersion
    [-Version] <string>
    [-Target] <string>
    [<CommonParameters>]
```

### DESCRIPTION

Compare two versions using the PSADTNXT.Application.NxtVersion class, which supports a wide range of version formats.
Known formats include:
- `1.2.3`
- `1.2a`
- `1.2-prerelease+build`
- `v1.2`
- `1.2 (build 123)`
- `2025-01-01`

### EXAMPLES

#### Example 1

```PowerShell
Compare-NXTVersion -Version '1.2.3.4' -Target '4.3.2.1'
```

Will return [PSADTNXT.Application.VersionCompareResult]::Update.

### INPUTS

System.String - The base version to compare.

### OUTPUTS

PSADTNXT.Application.VersionCompareResult - The result of the comparison.

### PARAMETERS

#### -Version

The version to compare.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

#### -Target

The target version to compare against.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## ConvertFrom-NXTCommandLine

Converts an escaped string into a list of components.

### SYNTAX

```PowerShell
ConvertFrom-NXTCommandLine
    [-InputObject] <string>
    [<CommonParameters>]
```

### DESCRIPTION

Interprets the input string as a command line, and returns an array of strings that represent the command line components.

### EXAMPLES

#### Example 1

```PowerShell
ConvertFrom-NXTEscapedString -InputObject '"C:\my program.exe" -Argument1 "Value 1" -Argument2 '''Value 2''''
```

This will return an array of strings: 'C:\my program.exe', '-Argument1', 'Value 1', '-Argument2', 'Value 2'.

### INPUTS

System.String - The escaped string that should be convert into a list of components.

PSADTNXT.Package.NxtRegisteredPackage - A registered package for which to retrieve the uninstall arguments.

PSADT.Types.InstalledApplication - An installed application for which to retrieve the uninstall arguments.

### OUTPUTS

System.String[] - An array of strings that represent the command line components.

### PARAMETERS

#### -InputObject

The escaped string that you want to convert into a list of components.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

## ConvertFrom-NXTEncodedObject

Converts a Base64-encoded and compressed object string into a PowerShell object.

### SYNTAX

```PowerShell
ConvertFrom-NXTEncodedObject
    [-InputObject] <string>
    [-AsHashTable]
    [<CommonParameters>]
```

### DESCRIPTION

Deserializes a given Base64-encoded and compressed string back into its original type.

### EXAMPLES

#### Example 1

```PowerShell
"eJyzVnLPLEvN80vMTVWyUvLKz8hT0lEKLi2CCrjkpyrV6qAq8k2sQFHjW1pcklqUm5iXp1QbCwCmtj3M" | ConvertFrom-NXTEncodedObject
```

This example demonstrates how to decode a Base64-encoded and compressed string into a object.

### INPUTS

System.String - The Base64-encoded and compressed string to decode.

### OUTPUTS

System.Object - The deserialized object.

### PARAMETERS

#### -InputObject

The Base64-encoded and compressed string to decode.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -AsHashTable

When specified, the output object will be converted to a hashtable instead of a PSCustomObject.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## ConvertFrom-NXTJson

Converts a JSON string to a custom object.

### SYNTAX

```PowerShell
ConvertFrom-NXTJson
    [-InputObject] <string>
    [-AsHashTable]
    [<CommonParameters>]
```

### DESCRIPTION

The ConvertFrom-NXTJson function converts a JSON string to a custom object.
It enables the feature set of PowerShell Core's Cmdlet in Windows PowerShell 5.1.

### EXAMPLES

#### Example 1

```PowerShell
'{"key": "value"}' | ConvertFrom-NXTJson
```

This will return a custom object with the key 'key' and the value 'value'.

### INPUTS

System.String - The JSON string to convert.

### OUTPUTS

System.Management.Automation.PSObject - The custom object created from the JSON string.
System.Collections.Hashtable - The custom object created from the JSON string if the `-AsHashTable` parameter is specified.

### PARAMETERS

#### -InputObject

The JSON string to convert.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -AsHashTable

When specified, the function will return a hashtable instead of a custom object.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## ConvertFrom-NXTProductCode

Converts an installer product code into a product GUID.

### SYNTAX

```PowerShell
ConvertFrom-NXTProductCode
    [-ProductCode] <string>
    [<CommonParameters>]
```

### DESCRIPTION

Converts an installer product code into a product GUID.

### EXAMPLES

#### Example 1

```PowerShell
"74A40E43AE252A33DA9C28656E1F4E10" | ConvertFrom-NXTProductCode
```

Converts the installer product code into a product GUID.

### INPUTS

System.String - The installer product code to convert.

### OUTPUTS

System.Guid - The product GUID.

### PARAMETERS

#### -ProductCode

The installer product code that you want to convert into a product GUID.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

## ConvertTo-NXTEncodedObject

Converts a object into a Base64-encoded and compressed json string.

### SYNTAX

```PowerShell
ConvertTo-NXTEncodedObject
    [-InputObject] <Object>
    [-Depth <uint16>]
    [<CommonParameters>]
```

### DESCRIPTION

The ConvertTo-NxtEncodedObject function takes an object as input and performs three main operations:
1. Serializes the object via ConvertTo-Json.
2. Compresses the string using a deterministic compression algorithm.
3. Encodes the compressed data into a Base64 string.
This function is useful for securely and efficiently transmitting objects or using them in parameterized commands.

### EXAMPLES

#### Example 1

```PowerShell
@{ Name = 'Jane'; Details = @{ Age = 25; Occupation = 'Engineer' } } | ConvertTo-NXTEncodedObject
```

This example demonstrates how to convert a nested object into a Base64-encoded and compressed string.

### INPUTS

System.Object - The object to convert.

### OUTPUTS

System.String - The Base64-encoded and compressed string representation of the object.

### PARAMETERS

#### -InputObject

The object to convert.

|Property|Value|
|:---|:---|
|Type:|Object|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -Depth

The maximum depth of the object to serialize.

|Property|Value|
|:---|:---|
|Type:|UInt16|
|Position:|Named|
|Default value:|2|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## ConvertTo-NXTInstallerProductCode

Converts a product GUID into an installer product code.

### SYNTAX

```PowerShell
ConvertTo-NXTInstallerProductCode
    [-Guid] <guid>
    [<CommonParameters>]
```

### DESCRIPTION

Converts a product GUID into an installer product code.

### EXAMPLES

#### Example 1

```PowerShell
"{12345678-1234-1234-1234-123456789012}" | ConvertTo-NxtInstallerProductCode
```

Converts the product GUID into an installer product code.

### INPUTS

System.Guid - The product GUID to convert.

### OUTPUTS

System.String - The installer product code.

### PARAMETERS

#### -Guid

The product GUID that you want to convert into an installer product code.

|Property|Value|
|:---|:---|
|Type:|Guid|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

## ConvertTo-NXTProductCode

Converts a product GUID into an installer product code.

### SYNTAX

```PowerShell
ConvertTo-NXTProductCode
    [-Guid] <guid>
    [<CommonParameters>]
```

### DESCRIPTION

Converts a product GUID into an installer product code.

### EXAMPLES

#### Example 1

```PowerShell
"{12345678-1234-1234-1234-123456789012}" | ConvertTo-NXTProductCode
```

Converts the product GUID into an installer product code.

### INPUTS

System.Guid - The product GUID to convert.

### OUTPUTS

System.String - The installer product code.

### PARAMETERS

#### -Guid

The product GUID that you want to convert into an installer product code.

|Property|Value|
|:---|:---|
|Type:|Guid|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

## ConvertTo-NXTPsArgumentString

Converts a dictionary object to an argument list.

### SYNTAX

```PowerShell
ConvertTo-NXTPsArgumentString
    [-InputObject] <hashtable>
    [-StringDelimiter <string>]
    [-StringDelimiterReplacement <string>]
    [-UseEnumValue]
    [<CommonParameters>]
```

### DESCRIPTION

Converts a dictionary object to an argument list. The dictionary keys are used as the parameter names and the values are used as the parameter values.
Be aware that only types that can be converted from and to a string are supported.
Additionally, switch and boolean values are supported.

### EXAMPLES

#### Example 1

```PowerShell
@{ 'Key1' = 'Value1'; 'Key2' = 'Value2' } | ConvertTo-NXTPsArgumentString
```

Will return a argument string with named parameters: `-Key1 "Value1" -Key2 "Value2"`.

#### Example 2

```PowerShell
@{ 1 = 'Value1'; 2 = 'Value2' } | ConvertTo-NXTPsArgumentString
```

Will return a argument string with positional parameters: `"Value1" "Value2"`.

### INPUTS

System.Collections.Hashtable - The dictionary object to convert.

System.Management.Automation.InvocationInfo - The bound parameters of the current command.

### OUTPUTS

System.String - The argument list.

### PARAMETERS

#### -InputObject

The dictionary object to convert. If the keys are integers, they will be treated as positional parameters, otherwise they will be treated as named parameters.

|Property|Value|
|:---|:---|
|Type:|Hashtable|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -StringDelimiter

The string delimiter to use if the string value contains tokens that need to be escaped.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|"|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -StringDelimiterReplacement

The replacement string for string delimiters within the string value.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|StringDelimiter's default escape replacement.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -UseEnumValue

Use the enum value instead of the enum name.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Exit-NXTDeployment

This a helper function that allows ending the deployment process.

### SYNTAX

```PowerShell
# ParameterSet ExitCode
Exit-NXTDeployment
    [-Message] <string>
    [[-ExitCode] <int>]
    [-ADTSession <NxtDeploymentSession>]
    [-NoRegistration]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Status
Exit-NXTDeployment
    [[-Message] <string>]
    -Status <DeploymentStatus>
    [-ADTSession <NxtDeploymentSession>]
    [-NoRegistration]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet AbortReboot
Exit-NXTDeployment
    [[-Message] <string>]
    -AbortReboot
    [-ADTSession <NxtDeploymentSession>]
    [<CommonParameters>]
```

### DESCRIPTION

This a helper function that allows ending the deployment process by throwing a NxtDeploymentCancelException.
The exception is caught by the Invoke-NXTDeployment function and the deployment process will be ended.

### EXAMPLES

#### Example 1

```PowerShell
Exit-NXTDeployment -Message "Deployment should stop here. No error was reported." -ExitCode 0
```

This will halt the deployment process and will only run post-deployment tasks.

#### Example 2

```PowerShell
Exit-NXTDeployment -Status 'Error'
```

This will halt the deployment process and will only run post-deployment tasks and mark the deployment as failed.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -ADTSession

The deployment session object representing the current deployment.

|Property|Value|
|:---|:---|
|Type:|NxtDeploymentSession|
|Position:|Named|
|Default value:|(& $script:CommandTable.'Get-ADTSession')|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Message

The message to be displayed in the exception.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ExitCode

The exit code to set for the deployment session.

|Property|Value|
|:---|:---|
|Type:|Int32|
|Position:|1|
|Default value:|0|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Status

Apply a predefined exit code and message representing the given status.

|Property|Value|
|:---|:---|
|Type:|DeploymentStatus|
|Enum values:|Complete, RestartRequired, FastRetry, Error|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AbortReboot

A quick access switch to set the exit code to 3010, NoRegistration to true and a predefined message.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoRegistration

Will set the Register property of the package to false.
Additionally if the package is registered, it will be unregistered.
This is useful for requiring a restart of the system before the package is considered deployed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Expand-NXTVariablesInFile

Expands different variable types in a given text file.

### SYNTAX

```PowerShell
# ParameterSet Path
Expand-NXTVariablesInFile
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Expand-NXTVariablesInFile
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Designed to expand a variety of variable types present in a text file.
The function is equipped to handle Windows style environment variables, PowerShell variables and PowerShell subexpression operators.
Upon execution, the function will update the target file by replacing all variable references with their actual values.
The file does not need to be a PowerShell script, but the function will only expand variables that are valid in PowerShell.

### EXAMPLES

#### Example 1

```PowerShell
Expand-NXTVariablesInFile -Path 'C:\Temp\test.txt' -Variables @(Get-Variable 'MyVar1', 'MyVar2')
```

Expands the variables in the file 'C:\Temp\test.txt' using the values of the PowerShell variables 'MyVar1' and 'MyVar2'.

### INPUTS

System.String[] - The path to the file(s) to expand variables in.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the file(s) to expand variables in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to expand variables in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTApplication

Retrieves the application matching the application search criteria.

### SYNTAX

```PowerShell
# ParameterSet Manual
Get-NXTApplication
    [-Store <ApplicationStore>]
    [-Identifier <string>]
    [-Filter <scriptblock>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Criteria
Get-NXTApplication
    [-Criteria] <NxtApplicationCriteria>
    [<CommonParameters>]
```

### DESCRIPTION

Retrieves the application matching the application search criteria.
The function queries the specified application store for entries matching the identifier and applies an optional filter to find the desired application(s).
If no Identifier is provided, all applications from the specified store are returned and filtered accordingly.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTApplication -Criteria @{ Store = 'ARP'; Identifier = 'TestApp' }
```

Retrieves the application from the ARP store with an identifier of 'TestApp'.

#### Example 2

```PowerShell
Get-NXTApplication -Store 'ARP' -Filter { $_.DisplayVersion -like '1.*' }
```

Retrieves all applications from the ARP store with a display version starting with '1.'.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

`[PSADT.Types.InstalledApplication]`
### PARAMETERS

#### -Criteria

The application search criteria used to find the application(s).

|Property|Value|
|:---|:---|
|Type:|NxtApplicationCriteria|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -Store

The application store to query for applications. This parameter is used when the Criteria parameter set is not used.

|Property|Value|
|:---|:---|
|Type:|ApplicationStore|
|Enum values:|Package, ARP, ARP32, ARP64, AppX|
|Position:|Named|
|Default value:|[PSADTNXT.Application.ApplicationStore]::ARP|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Identifier

The identifier to search for in the specified store. This parameter is used when the Criteria parameter set is not used.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Filter

An optional script block used to filter the retrieved applications. The script block should return $true for the desired application(s). This parameter is used when the Criteria parameter set is not used.

|Property|Value|
|:---|:---|
|Type:|ScriptBlock|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTCommandTable

Retrieves the NXT command table of this module.

### SYNTAX

```PowerShell
Get-NXTCommandTable
    
```

### DESCRIPTION

This command table includes the base PSADT command table and functions from the current module.


### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

`[System.Collections.ObjectModel.ReadOnlyDictionary`2[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089],[System.Management.Automation.CommandInfo, System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]]]`
### PARAMETERS

**This function does not have any documented parameters.**
## Get-NXTContent

Replaces `Get-Content` with neo42 encoding handling for files.

### SYNTAX

```PowerShell
# ParameterSet Path
Get-NXTContent
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-Encoding <Encoding>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Get-NXTContent
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-Encoding <Encoding>]
    [<CommonParameters>]
```

### DESCRIPTION

It's use is limited to only files and it will determine the encoding of the file and use that if no encoding is specified.
Should the detection fail, or if the file doesn't exist, it will use the encoding defined in the DefaultEncoding parameter.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTContent -Path 'C:\Temp\test.txt'
```

Gets the content of the file 'C:\Temp\test.txt'.

#### Example 2

```PowerShell
Get-NXTContent -Path 'C:\Temp\test.txt' -Encoding UTF8
```

Gets the content of the file 'C:\Temp\test.txt' using the UTF8 encoding.

### INPUTS

System.IO.FileInfo[] - The file(s) to get content from.

### OUTPUTS

System.String - The content of the file(s).

### PARAMETERS

#### -Path

The path to the file(s) to get content from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to get content from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to read the file with. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTDriveFreeSpace

Retrieves the free space in a given unit.

### SYNTAX

```PowerShell
Get-NXTDriveFreeSpace
    [-Name] <string>
    [[-Unit] <DataSizeUnit>]
    [<CommonParameters>]
```

### DESCRIPTION

Retrieves the free space in a given unit. The default unit is bytes.
If the drive is not mounted, or the drive name is invalid, an error will be thrown.

> **NOTE**
>
> The output is rounded down to the nearest whole number.
> 
> 
### EXAMPLES

#### Example 1

```PowerShell
Get-NxtDriveFreeSpace -DriveName "C:"
```

This example retrieves the free space of the C: drive in bytes.

#### Example 2

```PowerShell
Get-NxtDriveFreeSpace -DriveName "D" -Unit "GB"
```

This example retrieves the free space of the D: drive in gigabytes.

#### Example 3

```PowerShell
Get-PSDrive C | Get-NxtDriveFreeSpace -Unit "GB"
```

This example retrieves the type of the C: drive using the PSProvider and converts the output to gigabytes.
### INPUTS

System.String - The drive letter or ID of the drive to check.

System.Management.Automation.PSDriveInfo - The PSDriveInfo object to check.

Microsoft.Management.Infrastructure.CimInstance - The MSFT_Volume cim instance to check.

### OUTPUTS

System.UInt64 - The free space in the specified unit.

### PARAMETERS

#### -Name

A string representing the drive letter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Unit

The output unit size. The default is bytes.

|Property|Value|
|:---|:---|
|Type:|DataSizeUnit|
|Enum values:|B, KB, MB, GB, TB, PB|
|Position:|1|
|Default value:|[PSADTNXT.IO.DataSizeUnit]::B|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTDriveType

Retrieves the drive type of a given drive.

### SYNTAX

```PowerShell
Get-NXTDriveType
    [-Name] <string>
    [<CommonParameters>]
```

### DESCRIPTION

The Get-NxtDriveType function determines the type of a given drive.
If an invalid drive name is provided, it will throw an error. If the drive is not mounted, NoRootDirectory will be returned.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTDriveType -Name "C:"
```

This example retrieves the type of the C: drive.

#### Example 2

```PowerShell
Get-PSDrive C | Get-NXTDriveType
```

This example retrieves the type of the C: drive using the PSProvider.

#### Example 3

```PowerShell
Get-Volume -DriveLetter C | Get-NXTDriveType
```

This example retrieves the type of the C: drive using the Get-Volume cmdlet (uses CimInstance).

### INPUTS

System.String - The drive letter or ID of the drive to check.

System.Management.Automation.PSDriveInfo - The PSDriveInfo object to check.

Microsoft.Management.Infrastructure.CimInstance - The MSFT_Volume cim instance to check.

### OUTPUTS

System.IO.DriveType - The type of the drive.

### PARAMETERS

#### -Name

A string representing the drive letter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

## Get-NXTFileEncoding

Gets the estimated encoding of a file based on BOM and other heuristics.

### SYNTAX

```PowerShell
# ParameterSet Path
Get-NXTFileEncoding
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-DefaultEncoding <Encoding>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Get-NXTFileEncoding
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-DefaultEncoding <Encoding>]
    [<CommonParameters>]
```

### DESCRIPTION

The Get-NxtFileEncoding function returns the estimated encoding of a file based on the presence of a Byte Order Mark (BOM) and other heuristics.
If the encoding cant be detected, it will default to the provided DefaultEncoding.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTFileEncoding -Path 'C:\Temp\test.txt'
```

Gets the estimated encoding of the file 'C:\Temp\test.txt'.

### INPUTS

System.String - The path to the file to check for encoding.

System.IO.FileInfo - The file to check for encoding.

### OUTPUTS

System.Text.Encoding - The estimated encoding of the file.

### PARAMETERS

#### -Path

The path to the file(s) to check for encoding.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to check for encoding.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DefaultEncoding

The default encoding to use if the file does not exist or if the encoding cannot be detected.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|$OutputEncoding - Will use the caller's OutputEncoding.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTFolderSize

Retrieves the size of the specified folder recursively, in the given unit.

### SYNTAX

```PowerShell
# ParameterSet Path
Get-NXTFolderSize
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Unit <DataSizeUnit>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Get-NXTFolderSize
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Unit <DataSizeUnit>]
    [<CommonParameters>]
```

### DESCRIPTION

The Get-NxtFolderSize function calculates the size of the specified folder, including all of its sub folders and files.
It supports various units for the output size, such as bytes, kilobytes, megabytes, gigabytes, and terabytes.

### EXAMPLES

#### Example 1

```PowerShell
Get-NxtFolderSize "D:\setup\"
```

Retrieves the size of the folder located at "D:\setup\" in bytes.

#### Example 2

```PowerShell
Get-NxtFolderSize "C:\Users\User\Documents" -Unit "MB"
```

Retrieves the size of the folder located at "C:\Users\User\Documents" in megabytes.

### INPUTS

System.String[] - The path to the folder(s) to calculate the size of.

System.IO.DirectoryInfo[] - The folder(s) to calculate the size of.

### OUTPUTS

System.UInt64 - The size of the folder(s) in the specified unit.

### PARAMETERS

**This function does not have any documented parameters.**
## Get-NXTParentProcess

Retrieves the parent process of a given process ID.

### SYNTAX

```PowerShell
Get-NXTParentProcess
    [[-Id] <uint32>]
    [-Recurse]
    [-Depth <uint16>]
    [<CommonParameters>]
```

### DESCRIPTION

Retrieves the parent process(es) of a given process ID in order.
It can optionally retrieve the entire parent hierarchy by using the `-Recurse` switch.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTParentProcess -Id 1234
```

Retrieves the parent process of the process with ID 1234.

#### Example 2

```PowerShell
Get-NXTParentProcess -Id 1234 -Recurse -Depth 5
```

Retrieves the parent process hierarchy of the process with ID 1234, up to a depth of 5.

### INPUTS

System.UInt32 - The process ID to check.

System.Diagnostics.Process - The process to check.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.

### OUTPUTS

System.Diagnostics.Process[] - The parent process(es) of the specified process ID.

### PARAMETERS

#### -Id

The process ID of the child process.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|0|
|Default value:|$PID|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Recurse

Recursively retrieves the parent process hierarchy.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Depth

The maximum number of parent processes to retrieve.

|Property|Value|
|:---|:---|
|Type:|UInt16|
|Position:|Named|
|Default value:|20|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTProcessTree

Get the process tree for a given process ID

### SYNTAX

```PowerShell
Get-NXTProcessTree
    [[-Id] <uint32>]
    [-NoChildren]
    [-NoParents]
    [-Depth <uint16>]
    [<CommonParameters>]
```

### DESCRIPTION

It retrieves the parent process(es) and child process(es) of the specified process ID in order.

### EXAMPLES

#### Example 1

```PowerShell
`Get-NXTProcessTree -Id 1234`
```

Retrieves the process tree for the process with ID 1234.

#### Example 2

```PowerShell
Get-NXTProcessTree -Id 1234 -NoParents -Depth 1
```

Retrieves the child processes of the process with ID 1234, without retrieving parent processes.

### INPUTS

System.UInt32 - The process ID to check.

System.Diagnostics.Process - The process to check.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.

### OUTPUTS

System.Diagnostics.Process[] - The process tree for the specified process ID.

### PARAMETERS

#### -Id

The process ID of the process to get the tree for.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|0|
|Default value:|$PID|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -NoChildren

When specified, the function will not retrieve child processes.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoParents

When specified, the function will not retrieve parent processes.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Depth

The maximum number of child processes and parent processes to retrieve.
The value applies to both child and parent processes separately.

|Property|Value|
|:---|:---|
|Type:|UInt16|
|Position:|Named|
|Default value:|20|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTRegisteredPackage

Retrieves information about NXT registered packages on the current machine.

### SYNTAX

```PowerShell
# ParameterSet Filter
Get-NXTRegisteredPackage
    [-PackageId <guid>]
    [-Installed <bool>]
    [-Exclude <guid[]>]
    [-RegPackagesKey <string>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Application
Get-NXTRegisteredPackage
    -Application <InstalledApplication>
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Session
Get-NXTRegisteredPackage
    [-ADTSession <NxtDeploymentSession>]
    [<CommonParameters>]
```

### DESCRIPTION

Gets details of the registered application packages installed on a local machine.
The function fetches details such as PackageGUID and InstallState.

### EXAMPLES

#### Example 1

```PowerShell
Get-NxtRegisteredPackage -Package "{12345678-1234-1234-1234-123456789012}" -Installed $false
```

This example retrieves information about a specific package that is registered but not installed.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

PSADTNXT.Package.NxtRegisteredPackage[] - An array of NxtRegisteredPackage objects.

### PARAMETERS

#### -PackageId

Filters the results based on the specified package ID.

|Property|Value|
|:---|:---|
|Type:|Guid|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Installed

Filters the results based on the installation state of the package.

|Property|Value|
|:---|:---|
|Type:|Boolean|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

Excludes the specified package IDs from the results.

|Property|Value|
|:---|:---|
|Type:|Guid[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Get-NXTStrictMode

Returns the currently applied strict mode version.

### SYNTAX

```PowerShell
Get-NXTStrictMode
    [<CommonParameters>]
```

### DESCRIPTION

Returns the currently applied strict mode version.

> **NOTE**
>
> This function tries to determine the currently applied strict mode version by causing an error in each version.
> Currently the maximum supported version is 3. If a higher version is released, this function will need to be updated.
> 
> 
### EXAMPLES

#### Example 1

```PowerShell
Get-NXTStrictMode
```

Returns the currently applied strict mode version as a System.Version object.
### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

[System.Version] or $null

### PARAMETERS

**This function does not have any documented parameters.**
## Get-NXTXmlNode

Retrieve nodes from an existing XML document.

### SYNTAX

```PowerShell
# ParameterSet Path
Get-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attribute <string>]
    [-Single]
    [-Force]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Get-NXTXmlNode
    -LiteralPath <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attribute <string>]
    [-Single]
    [-Force]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
Get-NXTXmlNode
    -XPath <string>
    [-InputObject <XmlNode[]>]
    [-Attribute <string>]
    [-Single]
    [-Force]
    [<CommonParameters>]
```

### DESCRIPTION

Retrieves nodes from an existing XML document. The nodes are retrieved at the specified XPath location.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child'
```

Removes the node 'child' from the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.

### INPUTS

System.Xml.XmlDocument[] - The XML document(s) to add the new node to.

System.IO.FileInfo[] - The XML file(s) to add the new node to.

### OUTPUTS

System.Xml.XmlDocument[] - The XML document(s) that were modified if the `-PassThru` parameter is specified.
System.String[] - The attribute value(s) of the node(s) that were retrieved.

### PARAMETERS

#### -Path

The path to the XML file(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created. If the file exists, the encoding will not be updated.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|XmlNode[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to remove.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Import-NXTIniFile

Imports an INI file.

### SYNTAX

```PowerShell
# ParameterSet Path
Import-NXTIniFile
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-AsIniDocument]
    [-Encoding <Encoding>]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Import-NXTIniFile
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-AsIniDocument]
    [-Encoding <Encoding>]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

### DESCRIPTION

Imports an INI file as a hashtable or as an IniDocument object with comments.

### EXAMPLES

#### Example 1

```PowerShell
Import-NXTIniFile -Path 'C:\Temp\test.ini'
```

Imports the INI file 'C:\Temp\test.ini' as hashtable.

#### Example 2

```PowerShell
Import-NXTIniFile -Path 'C:\Temp\test' -AsIniDocument
```

Imports the INI file 'C:\Temp\test.ini' as an IniDocument object with comments.

### INPUTS

System.String - The path to the INI file(s) to import.

System.IO.FileInfo - The INI file(s) to import.

### OUTPUTS

System.Collections.Hashtable - The INI file as a hashtable if the `-AsIniDocument` parameter is specified.
PSADTNXT.Configuration.NxtIniDocument - The INI file as an IniDocument object with comments.

### PARAMETERS

#### -Path

The path to the INI file(s) to import.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the INI file(s) to import.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AsIniDocument

When specified, the function will return an IniDocument object with comments.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -UnboundArguments

Unbound arguments that are passed to the function. These will be ignored but are useful for easier invocation of the function.

|Property|Value|
|:---|:---|
|Type:|List[Object]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByRemainingArguments)|
|Accept wildcard characters:|False|

## Import-NXTXmlFile

Imports an XML file.

### SYNTAX

```PowerShell
# ParameterSet Path
Import-NXTXmlFile
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Import-NXTXmlFile
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

### DESCRIPTION

Imports an XML file.

### EXAMPLES

#### Example 1

```PowerShell
Import-NXTXmlFile -Path 'C:\Temp\test.xml'
```

Imports the XML file 'C:\Temp\test.xml' as XmlDocument.

### INPUTS

System.String - The path to the XML file(s) to import.

### OUTPUTS

System.Xml.XmlDocument - The XML file as an XmlDocument object.

### PARAMETERS

#### -Path

The path to the XML file(s) to import.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to import.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -UnboundArguments

Unbound arguments that are passed to the function. These will be ignored but are useful for easier invocation of the function.

|Property|Value|
|:---|:---|
|Type:|List[Object]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByRemainingArguments)|
|Accept wildcard characters:|False|

## Install-NXTApplication

Installs an application based on the neo42 logic.

### SYNTAX

```PowerShell
# ParameterSet ExitCodes
Install-NXTApplication
    [-Target] <string>
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-Method <DeploymentMethod>]
    [-Criteria <NxtApplicationCriteria>]
    [-LogFileName <string>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-ExitOnProcessFailure]
    [-SuccessExitCodes <int[]>]
    [-RebootExitCodes <int[]>]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet IgnoreExitCodes
Install-NXTApplication
    [-Target] <string>
    -IgnoreExitCodes
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-Method <DeploymentMethod>]
    [-Criteria <NxtApplicationCriteria>]
    [-LogFileName <string>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-NoCache]
    [<CommonParameters>]
```

### DESCRIPTION

Contains all installer specific code to install and repair an application.

### EXAMPLES

#### Example 1

```PowerShell
Install-NXTApplication -Target 'C:\Temp\test.msi' -ArgumentList '/quiet /norestart' -Method MSI
```

Installs the application using the MSI method with the specified arguments.

#### Example 2

```PowerShell
Install-NXTApplication -Target 'setup.exe' -Method Setup -AdditionalArgumentList '/silent' -LogFileName 'CustomInstall.log' -Criteria @{ Store = 'ARP'; Identifier = 'TestApp' }
```

Installs the application using the Setup method with the specified additional arguments and a custom log file name. The criteria is used to find the installed application for caching purposes.

### INPUTS

System.IO.FileInfo - The path to the installer.

### OUTPUTS

PSADT.ProcessManagement.ProcessResult - The result of the installation process.

### PARAMETERS

#### -Target

The path or other identifier of the installer.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ArgumentList

The arguments to pass to the installer.
This parameter will replace the default arguments of the defined Method.
Be aware that arguments are automatically escaped to ensure that they are properly formatted for the process start.
Manual escaping will be passed as a literal string to the process.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AdditionalArgumentList

Additional arguments to pass to the installer. These are appended to ArgumentList.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Method

The method to use for the installation.

|Property|Value|
|:---|:---|
|Type:|DeploymentMethod|
|Enum values:|Setup, Copy, MSI, InnoSetup, Nullsoft, BitRockInstaller, Burn, AppX|
|Position:|Named|
|Default value:|Setup|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LogFileName

The path to the log file ending with a .log extension.
This file will reside in the log directory of the ADT session.
The resulting full path is available as %LogFile% in the ArgumentList.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|ID.$deploymentTimestamp.log|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Criteria

An instance of NxtApplicationCriteria to search for the application. Is used for advanced scenarios like caching the uninstaller post installation.
Usually not required, as the ADT session will provide a default instance.

|Property|Value|
|:---|:---|
|Type:|NxtApplicationCriteria|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CacheDirectory

The directory where the package cache is located. This is used to store the uninstaller files if the NoCache parameter is not specified.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|(& $script:CommandTable.'Get-ADTSession').NXT.Package.Directory|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Awaiter

Optional awaiter objects that should be evaluated post installation.

|Property|Value|
|:---|:---|
|Type:|INxtAwaiter[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -SuccessExitCodes

The exit codes that indicate a successful installation. If the exit code of the process is in this list, the installation is considered successful.

|Property|Value|
|:---|:---|
|Type:|Int32[]|
|Position:|Named|
|Default value:| - Defaults depend on the method and session configuration.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -RebootExitCodes

The exit codes that indicate a reboot is required after the installation. If the exit code of the process is in this list, the installation is considered successful and a reboot is requested.

|Property|Value|
|:---|:---|
|Type:|Int32[]|
|Position:|Named|
|Default value:| - Defaults depend on the method and session configuration.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ExitOnProcessFailure

Determines if the function should exit with an error if the process fails. If this parameter is specified, the deployment will be aborted.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -IgnoreExitCodes

Specifies that any exit code from the installation process should be ignored and treated as a success.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoCache

For specific methods a copy of the uninstaller will be created in the cache directory. Specify this parameter to skip this step.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Invoke-NXTDeployment

This is the main function to deploy software packages.

### SYNTAX

```PowerShell
Invoke-NXTDeployment
    [[-ADTSession] <NxtDeploymentSession>]
    [<CommonParameters>]
```

### DESCRIPTION

This function is the main function to deploy software packages.
It handles all the necessary steps to deploy a software package based on the configuration file.
Custom hook points are available to extend the deployment logic.

### EXAMPLES

#### Example 1

```PowerShell
Invoke-NXTDeployment -ADTSession $adtSession
```

Invokes the deployment logic for the specified ADT session.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -ADTSession

The ADT session for which the deployment is performed. This parameter is optional and will be set to the current ADT session if not specified.

|Property|Value|
|:---|:---|
|Type:|NxtDeploymentSession|
|Position:|0|
|Default value:|(& $script:CommandTable.'Get-ADTSession')|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## New-NXTEnvironmentTable

Creates a new environment table.

### SYNTAX

```PowerShell
New-NXTEnvironmentTable
    [<CommonParameters>]
```

### DESCRIPTION

Creates a new environment table. Used to substitute the environment table in the ADT session.
This function is supposed to be used in conjunction with Initialize-ADTSession's `-AdditionalEnvironmentVariables` parameter.


### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

`[System.Collections.ObjectModel.ReadOnlyDictionary`2[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089],[System.Object, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]]`
### PARAMETERS

**This function does not have any documented parameters.**
## New-NXTFolderWithPermission

Creates a new folder with predefined permissions.

### SYNTAX

```PowerShell
# ParameterSet Path
New-NXTFolderWithPermission
    [-Path] <string[]>
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Owner <IdentityReference>]
    [-CustomDirectorySecurity <DirectorySecurity>]
    [-Hide]
    [-Force]
    [-Inherit]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Creates a new folder with predefined permissions.

### EXAMPLES

#### Example 1

```PowerShell
New-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'
```

Creates a new folder at 'C:\Temp\MyFolder' with full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone', and sets 'DOMAIN\User1' as the owner.

### INPUTS

System.String - The path to the folder(s) to create.

### OUTPUTS

System.IO.DirectoryInfo[] - The created folder(s).

### PARAMETERS

#### -Path

The path to the folder to create.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -FullControl

The user(s) or group(s) to grant full control permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Write

The user(s) or group(s) to grant write permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Modify

The user(s) or group(s) to grant modify permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ReadAndExecute

The user(s) or group(s) to grant read and execute permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Owner

The user or group to set as the owner of the folder.

|Property|Value|
|:---|:---|
|Type:|IdentityReference|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CustomDirectorySecurity

A custom DirectorySecurity object to use as base for the folder permissions. Default is a new DirectorySecurity object.

|Property|Value|
|:---|:---|
|Type:|DirectorySecurity|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Hide

Specifies that the folder should be hidden.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Specifies that if the folder already exists, it should be deleted and recreated.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Inherit

Specifies that the folder should inherit permissions from the parent folder. Otherwise, the permissions are protected.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Returns the created folder if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## New-NXTSessionParameter

Retrieves the parameters for the the Open-ADTSession function.

### SYNTAX

```PowerShell
New-NXTSessionParameter
    [-Invocation] <InvocationInfo>
    [[-ScriptDirectory] <DirectoryInfo>]
    [[-SetupCfg] <FileInfo[]>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Collects all required parameters for the Open-ADTSession function and returns them as a dictionary for use with Open-ADTSession.

### EXAMPLES

#### Example 1

```PowerShell
Get-NXTSessionParameter -Invocation $MyInvocation
```

Retrieves the parameters for the Open-ADTSession function from the current invocation.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

System.Collections.Generic.Dictionary[System.String, System.Object] - The parameters for the Open-ADTSession function.

### PARAMETERS

#### -Invocation

The invocation of the deploy script to retrieve the parameters from.

|Property|Value|
|:---|:---|
|Type:|InvocationInfo|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ScriptDirectory

The directory from which all source files are read. Defaults to the invocation script location.

|Property|Value|
|:---|:---|
|Type:|DirectoryInfo|
|Position:|1|
|Default value:|[System.IO.Path]::GetDirectoryName($Invocation.MyCommand.Definition)|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -SetupCfg

A list of paths to Setup.cfg files to load and merge for the session.

|Property|Value|
|:---|:---|
|Type:|FileInfo[]|
|Position:|2|
|Default value:|Setup.cfg, CustomSetup.cfg|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## New-NXTTemporaryFolder

Creates and configures a new temporary folder.

### SYNTAX

```PowerShell
New-NXTTemporaryFolder
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This function generates a new temporary folder in a specified or default root path, ensuring the folder has specific security permissions set.
If the provided root path doesn't exist or has incorrect permissions, it will be recreated accordingly.
The function ensures unique naming for the temporary folder and outputs its path upon successful creation.

### EXAMPLES

#### Example 1

```PowerShell
New-NxtTemporaryFolder
```

Will create a new folder.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

System.IO.DirectoryInfo - The created temporary folder.

### PARAMETERS

**This function does not have any documented parameters.**
## New-NXTXmlNode

Creates a new sub node in an existing XML document.

### SYNTAX

```PowerShell
# ParameterSet Path
New-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    -Name <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attributes <hashtable>]
    [-Prefix <string>]
    [-InnerText <string>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
New-NXTXmlNode
    -LiteralPath <string[]>
    -XPath <string>
    -Name <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Attributes <hashtable>]
    [-Prefix <string>]
    [-InnerText <string>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
New-NXTXmlNode
    -XPath <string>
    -Name <string>
    [-InputObject <XmlNode[]>]
    [-Attributes <hashtable>]
    [-Prefix <string>]
    [-InnerText <string>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Creates a new sub node in an existing XML document. The node is created at the specified XPath location.
The XPath must point to a single node. If the node already has child nodes, the -Force switch must be used to overwrite them.

### EXAMPLES

#### Example 1

```PowerShell
New-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent' -Name 'child' -Attributes @{ attr1 = 'value1'; attr2 = 'value2' } -InnerText 'Hello World'
```

Creates a new node 'child' in the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent'.
The new node will have the attributes 'attr1' and 'attr2' set to 'value1' and 'value2', respectively. The inner text of the new node will be set to 'Hello World'.

### INPUTS

System.Xml.XmlDocument[] - The XML document(s) to create the new node in.

System.IO.FileInfo[] - The XML file(s) to create the new node in.

### OUTPUTS

`[System.Xml.XmlDocument[]]`
### PARAMETERS

#### -Path

The path to the XML file(s) to create the node in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to create the node in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when writing and reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|$OutputEncoding|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to create the new node in.

|Property|Value|
|:---|:---|
|Type:|XmlNode[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to create the new node in.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Name

The name of the new node to create.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Attributes

A hashtable of attributes to set on the new node.

|Property|Value|
|:---|:---|
|Type:|Hashtable|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Prefix

The prefix to set on the new node.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InnerText

The inner text to set on the new node.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the existing child nodes should be removed before creating the new node.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Returns the XML document if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTDeploymentCallback

Removes a specific hook.

### SYNTAX

```PowerShell
Remove-NXTDeploymentCallback
    [-Callback] <CommandInfo[]>
    [[-HookPoint] <DeploymentHookPoint[]>]
    [<CommonParameters>]
```

### DESCRIPTION

The Remove-NXTDeploymentCallback function removes a custom hook from the deployment session that was previously added with Add-NXTDeploymentCallback.

### EXAMPLES

#### Example 1

```PowerShell
Add-NXTDeploymentCallback -HookPoint 'CustomInstallEnd' -Callback (Get-Command -Name 'My-CustomFunction')
```

This example adds a custom hook that executes the 'My-CustomFunction' function after the 'CustomInstallEnd' deployment hook point.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -HookPoint

The name of the deployment hook point after which the custom hook should be executed.

|Property|Value|
|:---|:---|
|Type:|DeploymentHookPoint[]|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTEmptyFolder

Removes only empty folders.

### SYNTAX

```PowerShell
# ParameterSet Path
Remove-NXTEmptyFolder
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-RootPath <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Remove-NXTEmptyFolder
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-RootPath <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This function is designed to remove folders if and only if they are empty.
If the specified folder contains any files or other items, the function continues without taking any action.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NxtEmptyFolder -Path "C:\Temp\MyFolder"
```

Removes the folder "C:\Temp\MyFolder" if it is empty.

### INPUTS

System.IO.DirectoryInfo[] - The folder(s) to remove.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the folder(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the folder(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden folders should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -RootPath

The path to the root folder to stop the recursion at.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTEmptyIniFile

Removes only empty INI files.

### SYNTAX

```PowerShell
# ParameterSet Path
Remove-NXTEmptyIniFile
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Remove-NXTEmptyIniFile
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This function is designed to remove INI files if and only if they are empty.
If the specified INI file contains any key-value pairs, the function continues without taking any action.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NxtEmptyIniFile -Path "SomeEmptyIniFile.ini"
```

Removes the INI file "SomeEmptyIniFile.ini" if it is empty.

### INPUTS

System.IO.FileInfo[] - The INI file(s) to remove.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the INI file(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the INI file(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTEmptyRegistryKey

Removes only empty registry keys

### SYNTAX

```PowerShell
Remove-NXTEmptyRegistryKey
    [-Key] <string>
    [-Wow6432Node]
    [-Sid <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This function is designed to remove registry keys if and only if they are empty. If the specified registry contains any values or sub keys,
the function continues without taking any action.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NxtEmptyRegistryKey -Key "HKLM:\Software\EmptyKey"
```

This example removes the specified empty key located at "HKLM:\Software\EmptyKey".

### INPUTS

Microsoft.Win32.RegistryKey[] - The registry key(s) to remove.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Key

The registry key(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Wow6432Node

Specifies whether to include the Wow6432Node on 64-bit systems.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Sid

The SID of the user to use for the registry key in case of a user registry key.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTPathVariable

Removes a path from the PATH environment variable.

### SYNTAX

```PowerShell
Remove-NXTPathVariable
    [-Path] <string[]>
    [-Target <EnvironmentVariableTarget>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

The Remove-NXTPathVariable cmdlet removes a path from the PATH environment variable of a specified target.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NXTPathVariable -Path 'C:\Program Files\Example\bin'
```

Removes the path 'C:\Program Files\Example\bin' from the PATH variable of the current process.

#### Example 2

```PowerShell
Remove-NXTPathVariable -Path 'C:\Program Files\Example\bin' -Target Machine
```

Removes the path 'C:\Program Files\Example\bin' from the PATH variable of the machine.

### INPUTS

System.String - The path(s) to remove from the PATH variable.

System.IO.FileInfo - The path(s) to remove from the PATH variable.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path(s) to remove from the PATH variable.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Target

Determines the scope of the PATH variable to be modified.

|Property|Value|
|:---|:---|
|Type:|EnvironmentVariableTarget|
|Enum values:|Process, User, Machine|
|Position:|Named|
|Default value:|Machine|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTService

Removes a service from the system.

### SYNTAX

```PowerShell
Remove-NXTService
    [-Name] <string[]>
    [[-Timeout] <timespan>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

The Remove-NXTService cmdlet removes a service from the system by stopping it and deleting it.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NXTService -Name 'MyService'
```

Removes the service named 'MyService' from the system, stopping it first if it is running.

#### Example 2

```PowerShell
Remove-NXTService -Name 'MyService' -Force
```

Removes the service named 'MyService' from the system without stopping it first and without validating dependencies.

### INPUTS

System.String - The name(s) of the service(s) to remove.

System.ServiceProcess.ServiceController - The service object(s) to remove.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Name

The name(s) of the service(s) to remove.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Will delete the service even if it did not stop in time, has dependencies or is already marked for deletion.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Timeout

The time to wait for the service to stop before removing it.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|1|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Remove-NXTXmlNode

Removes a node from an existing XML document.

### SYNTAX

```PowerShell
# ParameterSet Path
Remove-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Remove-NXTXmlNode
    -LiteralPath <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
Remove-NXTXmlNode
    -XPath <string>
    [-InputObject <XmlNode[]>]
    [-Force]
    [-PassThru]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Removes a node from an existing XML document. The node is removed at the specified XPath location.
The XPath must point to a single node. If the node has child nodes, the -Force switch must be used to remove them.

### EXAMPLES

#### Example 1

```PowerShell
Remove-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child'
```

Removes the node 'child' from the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.

### INPUTS

System.Xml.XmlNode[] - The XML node(s) or document(s) to remove the node from.

System.IO.FileInfo[] - The XML file(s) to remove the node from.

### OUTPUTS

System.Xml.XmlNode[] - The XML node(s) or document(s) that were modified if the `-PassThru` parameter is specified.

### PARAMETERS

#### -Path

The path to the XML file(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created. If the file exists, the encoding will not be updated.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|$OutputEncoding|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to remove the node from.

|Property|Value|
|:---|:---|
|Type:|XmlNode[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to remove.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if all matching nodes should be removed if more than one node is found.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Returns the XML document if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Resolve-NXTPath

Resolves common PowerShell path parameters to their qualified full paths.

### SYNTAX

```PowerShell
# ParameterSet Path
Resolve-NXTPath
    [-Path] <string[]>
    [-IncludeNonExistent]
    [-AsProviderPath]
    [-ProviderName <string>]
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-PathType <TestPathType>]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Resolve-NXTPath
    -LiteralPath <string[]>
    [-IncludeNonExistent]
    [-AsProviderPath]
    [-ProviderName <string>]
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Force]
    [-PathType <TestPathType>]
    [-UnboundArguments <List[Object]>]
    [<CommonParameters>]
```

### DESCRIPTION

Resolves common PowerShell path parameters to their qualified full paths.
It can take any object containing a `PSPath` that was retrieved via a PowerShell provider.
This function imitates the behavior of the PowerShell internal LocationGlobber.

### EXAMPLES

#### Example 1

```PowerShell
Resolve-NXTPath -Path "C:\Windows\System32\*" -Filter '*.exe' -Include 'cmd*'
```

Returns all executable files in the System32 directory that start with 'cmd'.

#### Example 2

```PowerShell
Resolve-NXTPath @PSBoundParameters -AsProviderPath
```

Returns the provider paths of all bound parameters that match a PowerShell path parameter.

#### Example 3

```PowerShell
Get-Item -Path "HKLM:\Software" | Resolve-NXTPath -AsProviderPath
```

Returns the `HKEY_LOCAL_MACHINE\Software` provider path for the given item.
### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

`[System.String[]]`
### PARAMETERS

#### -IncludeNonExistent

Includes non-existent paths in the output.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AsProviderPath

Returns the provider path instead of the fully qualified PSPath.
This is useful when when you work with .NET objects that do not support provider paths.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ProviderName

Will use the given provider to resolve the path. If not specified, the provider is determined from the path itself.
It is recommended to specify the provider in order to limit the output to a specific provider.
Specifying the provider will also enable to resolve provider paths. A useful example is the `Registry` provider

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Path

The path to resolve.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to resolve.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to apply to the resolved paths.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

An array of patterns to exclude from the resolved paths.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

An array of patterns to include in the resolved paths.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Forces the resolution of hidden or system items.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PathType

Limits the output to the given path type.
Useful for example to filter for files or directories.

|Property|Value|
|:---|:---|
|Type:|TestPathType|
|Enum values:|Any, Container, Leaf|
|Position:|Named|
|Default value:|Any|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Restart-NXTDeployScript

Restart the script if one of the conditions is met.

### SYNTAX

```PowerShell
Restart-NXTDeployScript
    [-Invocation] <InvocationInfo>
    [-When32on64Bit]
    [-WhenTriggerDeployment]
    [<CommonParameters>]
```

### DESCRIPTION

Designed as a helper script to remove as much logic as possible from the main script.
Restart conditions can be specified with the defined switch parameters.

> **NOTE**
>
> Be the script will run in a new process and the DeploymentType parameter will be cleared to avoid a trigger loop.
> The calling script will wait for the new process to finish and stop the execution with the exit code of the new process.
> Any logging to the console will be lost.
> 
> 
### EXAMPLES

#### Example 1

```PowerShell
Restart-NXTDeployScript -When32on64Bit -WhenTriggerDeployment
```

Restart the script when the current process is 32-bit on a 64-bit OS or when the DeploymentType parameter is a trigger.
### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Invocation

The invocation information of the current script.

|Property|Value|
|:---|:---|
|Type:|InvocationInfo|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -When32on64Bit

Restart the script if the current process is 32-bit on a 64-bit OS.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -WhenTriggerDeployment

Restart the script if the DeploymentType parameter is a trigger.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Set-NXTContent

Replaces `Set-Content` with neo42 encoding handling for files.

### SYNTAX

```PowerShell
# ParameterSet Path
Set-NXTContent
    [-Path] <string[]>
    [-Value] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-PassThru]
    [-NoNewLine]
    [-Force]
    [-Encoding <Encoding>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Set-NXTContent
    [-Value] <string[]>
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-PassThru]
    [-NoNewLine]
    [-Force]
    [-Encoding <Encoding>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

It's use is limited to only files and it will determine the encoding of the file and use that if no encoding is specified.
Should the detection fail, or if the file doesn't exist, it will use the encoding defined in the DefaultEncoding parameter.
Important note: If the file exists and the encoding is specified, the encoding will not be updated. Only the new content will be written with the specified encoding.

### EXAMPLES

#### Example 1

```PowerShell
Set-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World'
```

Sets the content 'Hello World' to the file 'C:\Temp\test.txt'.

#### Example 2

```PowerShell
Set-NXTContent -Path 'C:\Temp\test.txt' -Value 'Hello World' -Encoding UTF8
```
Sets the content 'Hello World' to the file 'C:\Temp\test.txt' using the UTF8 encoding.

### INPUTS

System.String[] - The content to set to the file(s).

System.IO.FileInfo[] - The file(s) to set content to.

### OUTPUTS

`System.String[]` - The content that was set to the file(s) if the `-PassThru` parameter is specified.

### PARAMETERS

#### -Path

The path to the file(s) to set content to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to set content to.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Value

The content to set to the file(s).

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -PassThru

Returns the content set to the file(s) if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoNewLine

Do not append a newline character to the content.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when the file is created. If the file exists, the encoding will not be updated.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Set-NXTFolderPermission

Replaces existing access control permissions on a specified, existing folder with the provided permissions.

### SYNTAX

```PowerShell
# ParameterSet Path
Set-NXTFolderPermission
    [-Path] <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Owner <IdentityReference>]
    [-CustomDirectorySecurity <DirectorySecurity>]
    [-Inherit]
    [-Recurse]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Set-NXTFolderPermission
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Owner <IdentityReference>]
    [-CustomDirectorySecurity <DirectorySecurity>]
    [-Inherit]
    [-Recurse]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

The function allows granular control over the access permissions of a specified folder.
It can assign specific permission levels (e.g., Full Control, Modify, Write, Read & Execute) to identity references (SID, user name or group name).
The function also provides options to set the owner, manage custom directory security settings, and control the inheritance of permissions.
It is capable of applying these settings to both the target folder and its sub-folders.

### EXAMPLES

#### Example 1

```PowerShell
New-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'
```

Sets permissions for folder 'C:\Temp\MyFolder' to full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone' and sets 'DOMAIN\User1' as the owner.

### INPUTS

System.String[] - The path to the folder(s) to set permissions on.

System.IO.DirectoryInfo[] - The folder(s) to set permissions on.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the folder(s) to set permissions on.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the folder(s) to set permissions on.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -FullControl

The user(s) or group(s) to grant full control permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Write

The user(s) or group(s) to grant write permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Modify

The user(s) or group(s) to grant modify permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ReadAndExecute

The user(s) or group(s) to grant read and execute permissions to.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Owner

The user or group to set as the owner of the folder.

|Property|Value|
|:---|:---|
|Type:|IdentityReference|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CustomDirectorySecurity

A custom DirectorySecurity object to use as base for the folder permissions. Default is a new DirectorySecurity object.

|Property|Value|
|:---|:---|
|Type:|DirectorySecurity|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Inherit

Specifies that the folder should inherit permissions from the parent folder. Otherwise, the permissions are protected.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Recurse

Specifies that the permissions should be applied to all sub-folders of the specified folder.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Set-NXTXmlNode

Updates an existing XML node in an XML document.

### SYNTAX

```PowerShell
# ParameterSet Path
Set-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Name <string>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Set-NXTXmlNode
    -LiteralPath <string[]>
    -XPath <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Encoding <Encoding>]
    [-Name <string>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
Set-NXTXmlNode
    -XPath <string>
    [-InputObject <XmlNode[]>]
    [-Name <string>]
    [-Attributes <hashtable>]
    [-InnerText <string>]
    [-PassThru]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

Updates an existing XML node in an XML document. The node is updated at the specified XPath location.
The XPath must point to a single node. Values of the specified node will be updated.

### EXAMPLES

#### Example 1

```PowerShell
Set-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent/child' -Attributes @{ attr1 = 'newValue1'; attr2 = 'newValue2' } -InnerText 'New Inner Text'
```

Updates the existing node 'child' in the XML document 'C:\Temp\test.xml' at the XPath location '/root/parent/child'.

### INPUTS

System.Xml.XmlNode[] - A node of an XML document(s) or the document(s) to update the node in.

System.IO.FileInfo[] - The XML file(s) to update the node in.

### OUTPUTS

System.Xml.XmlNode[] - The XML nodes or document(s) that were modified if the `-PassThru` parameter is specified.

### PARAMETERS

#### -Path

The path to the XML file(s) to update the node in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the XML file(s) to update the node in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to update.

|Property|Value|
|:---|:---|
|Type:|XmlNode[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to update.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Name

The name of the node to update.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Attributes

A hashtable of attributes to set on the node.

|Property|Value|
|:---|:---|
|Type:|Hashtable|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InnerText

The inner text to set on the node.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Returns the XML document if specified.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if the Read-Only attribute should be ignored when setting the content of the file or hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Show-NXTInstallationWelcome

Shows an installation welcome dialog to the user, optionally allowing them to defer the installation if blocking processes are detected.

### SYNTAX

```PowerShell
Show-NXTInstallationWelcome
    [[-Title] <string>]
    [[-CloseProcesses] <NxtCloseProcess[]>]
    [[-DeferTimes] <uint32>]
    [[-DeferDays] <uint32>]
    [[-DeferDeadline] <datetime>]
    [[-DeferRunInterval] <timespan>]
    [[-Timeout] <timespan>]
    [[-ContinueType] <ContinueType>]
    [[-ADTSession] <NxtDeploymentSession>]
    [-MinimizeWindows]
    [-CustomText]
    [-AllowDeferCloseProcesses]
    [-NotTopMost]
    [-PersistPrompt]
    [-HideCloseButton]
    [-AllowMove]
    [-NoBalloonTip]
    [-AllowDoNotDisturb]
    [-BlockExecution]
    [-DeploymentDefaults]
    [<CommonParameters>]
```

### DESCRIPTION

Shows an installation welcome dialog to the user, optionally allowing them to defer the installation if blocking processes are detected.
Wraps the Show-ADTInstallationWelcome function to provide NXT-specific functionality.
Enables support for reading values from the SetupCfg file and passing them to the Show-ADTInstallationWelcome function.

> **NOTE**
>
> This function is already built into the Invoke-NXTDeployment function.
> Only use this function if you want to show the installation welcome for custom cases.
> 
> 
### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Title

The title of the installation welcome dialog.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|$ADTSession.InstallTitle|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CloseProcesses

A list of processes that may block the installation.

|Property|Value|
|:---|:---|
|Type:|NxtCloseProcess[]|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ContinueType

The type of action to take if the the dialog times out.

|Property|Value|
|:---|:---|
|Type:|ContinueType|
|Enum values:|Abort, Continue|
|Position:|7|
|Default value:|Abort|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -MinimizeWindows

Whether to minimize all windows when the dialog is shown.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CustomText

Whether to show custom text in the dialog. The text is defined in the toolkit configuration.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AllowDeferCloseProcesses

Will allow the user to defer the installation.
Granular control is available via the DeferTimes, DeferDays, and DeferDeadline parameters.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DeferTimes

The number of times the user can defer the installation.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|2|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DeferDays

The number of days the user can defer the installation.
This option qualifies the DeferTimes option and is only used if DeferTimes is set.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|3|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DeferDeadline

The date and time when the installation can no longer be deferred. If DeferDays is set, the earliest date will be used.

|Property|Value|
|:---|:---|
|Type:|Nullable[DateTime]|
|Position:|4|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DeferRunInterval

A time span before the next interactive deployment is attempted.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|5|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NotTopMost

Whether to not show the dialog as a top-most window.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PersistPrompt

Whether to persist the prompt for the user to close blocking processes.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -HideCloseButton

Whether to hide the close button on the dialog.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AllowMove

Whether to allow the user to move the dialog.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoBalloonTip

Whether to suppress the balloon tip after the installation welcome dialog is closed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AllowDoNotDisturb

Whether to suppress the installation welcome dialog if the user has Do Not Disturb enabled on their session.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -BlockExecution

Whether to block the execution of the deployment until the deployment is closed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Timeout

The time to wait before the dialog times out.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|6|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -DeploymentDefaults

Whether to use the deployment defaults for the installation welcome dialog.
Any parameter specified will override the deployment defaults.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ADTSession

The current ADT session. Requires the extension session to be initialized.

|Property|Value|
|:---|:---|
|Type:|NxtDeploymentSession|
|Position:|8|
|Default value:|(& $script:CommandTable.'Get-ADTSession')|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Stop-NXTProcess

Stops a specified process using the given criteria.

### SYNTAX

```PowerShell
# ParameterSet Name
Stop-NXTProcess
    [-Name] <string[]>
    [-KillProcessTree]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Id
Stop-NXTProcess
    -Id <uint32[]>
    [-KillProcessTree]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Process
Stop-NXTProcess
    -Process <Process[]>
    [-KillProcessTree]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ProcessDefinition
Stop-NXTProcess
    -ProcessDefinition <ProcessDefinition[]>
    [-KillProcessTree]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This function stops a process based on its name, ID, or a filter applied to running processes.

### EXAMPLES

#### Example 1

```PowerShell
Stop-NXTProcess -Name "notepad.exe"
```

This example stops all instances of Notepad running on the system.

### INPUTS

System.String - The name of the process to stop.

System.UInt32 - The process ID to check.

System.Diagnostics.Process - The process to check.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to stop.

PSADT.ProcessManagement.ProcessDefinition - The process definition to stop.

PSADT.ProcessManagement.RunningProcess - The running process to stop.

PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Name

The name of the process to stop.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Id

The ID of the process to stop.

|Property|Value|
|:---|:---|
|Type:|UInt32[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Process

The process object to stop.

|Property|Value|
|:---|:---|
|Type:|Process[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

#### -ProcessDefinition

The process definition to stop.

|Property|Value|
|:---|:---|
|Type:|ProcessDefinition[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

#### -KillProcessTree

Include all child processes when stopping the specified process.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Test-NXTFileInUse

Test if a file is in use by another process.

### SYNTAX

```PowerShell
Test-NXTFileInUse
    [-Path] <string[]>
    [<CommonParameters>]
```

### DESCRIPTION

Test if a file is in use by another process. It can only successfully test if the process has read/write access to the file.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTFileInUse -Path 'C:\Temp\file.txt'
```

Check if the file 'C:\Temp\file.txt' is in use by another process.

### INPUTS

System.IO.FileInfo - The file to test.

### OUTPUTS

System.Boolean - Returns true if the file is in use by another process, otherwise false.

### PARAMETERS

#### -Path

The path to the file to test.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

## Test-NXTFolderPermission

Checks and compares the actual permissions of a specified folder against expected permissions.

### SYNTAX

```PowerShell
Test-NXTFolderPermission
    [-Path] <string>
    [-FullControl <IdentityReference[]>]
    [-Write <IdentityReference[]>]
    [-Modify <IdentityReference[]>]
    [-ReadAndExecute <IdentityReference[]>]
    [-Owner <IdentityReference>]
    [-CustomDirectorySecurity <DirectorySecurity>]
    [-IsInherited <bool>]
    [<CommonParameters>]
```

### DESCRIPTION

Test-NxtFolderPermissions evaluates a folder's security settings by comparing its actual permissions, owner, and other security attributes against predefined expectations.
It's useful for ensuring folder permissions align with security policies or compliance standards.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTFolderWithPermission -Path 'C:\Temp\MyFolder' -FullControl 'DOMAIN\User1', 'BuiltinAdministratorsSid' -Write 'S-1-1-0' -Owner 'DOMAIN\User1'
```

Tests if a folder 'C:\Temp\MyFolder' has these permissions: full control permissions for 'DOMAIN\User1' and 'Administrators', write permissions for 'Everyone', and 'DOMAIN\User1' as owner.

### INPUTS

System.IO.FileInfo - The folder to check.

### OUTPUTS

`[System.Boolean]`
### PARAMETERS

#### -Path

The path to the folder whose permissions are to be checked.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -FullControl

The user(s) or group(s) that should have full control permissions.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Write

The user(s) or group(s) that should have write permissions.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Modify

The user(s) or group(s) that should have modify permissions.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ReadAndExecute

The user(s) or group(s) that should have read and execute permissions.

|Property|Value|
|:---|:---|
|Type:|IdentityReference[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Owner

The user or group that should be set as the owner of the folder.

|Property|Value|
|:---|:---|
|Type:|IdentityReference|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CustomDirectorySecurity

A custom DirectorySecurity object to use as a base for the folder permissions. If not specified, a new DirectorySecurity object is created.

|Property|Value|
|:---|:---|
|Type:|DirectorySecurity|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -IsInherited

Test if permissions are inherited from the parent folder.

|Property|Value|
|:---|:---|
|Type:|Boolean|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Test-NXTIsSystemProcess

Checks if a process is running as the system account.

### SYNTAX

```PowerShell
Test-NXTIsSystemProcess
    [[-Id] <uint32>]
    [<CommonParameters>]
```

### DESCRIPTION

Checks if a process is running as the system account.

### EXAMPLES

#### Example 1

```PowerShell
Test-NxtIsSystemProcess -Id 1234
```

Checks if the process with ID 1234 is running as the system account.

### INPUTS

System.UInt32 - The process ID to check.

System.Diagnostics.Process - The process to check.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to check.

### OUTPUTS

System.Boolean - Returns true if the process is running as the system account, otherwise false.

### PARAMETERS

#### -Id

The process ID to check.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|0|
|Default value:|$PID|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

## Test-NXTProcess

Tests for the existence of a process.

### SYNTAX

```PowerShell
# ParameterSet Name
Test-NXTProcess
    [-Name] <string>
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Id
Test-NXTProcess
    -Id <uint32>
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ProcessDefinition
Test-NXTProcess
    -ProcessDefinition <ProcessDefinition>
    [<CommonParameters>]
```

### DESCRIPTION

The Test-NxtProcessExists function checks if a specified process is currently running on the system.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTProcess -Name "notepad.exe"
```

Tests if any instance of Notepad is running on the system.

### INPUTS

System.String - The name of the process to monitor.

System.UInt32 - The process ID to monitor.

System.Diagnostics.Process - The process to monitor.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.

### OUTPUTS

System.Boolean - Returns true if the process starts within the timeout period, otherwise false.

### PARAMETERS

#### -Name

The name(s) of the process to check for. This parameter is mandatory.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Id

The ID(s) of the process to check for. This parameter is optional and can be used instead of the Name parameter.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -ProcessDefinition

The process definition to check for.

|Property|Value|
|:---|:---|
|Type:|ProcessDefinition|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

## Test-NXTStringInFile

Searches for a specified string or regex pattern within a file.

### SYNTAX

```PowerShell
Test-NXTStringInFile
    [-Path] <string[]>
    [-Query] <string>
    [-PatternType <StringCompareOperator>]
    [-CaseSensitive]
    [-Encoding <Encoding>]
    [-Force]
    [<CommonParameters>]
```

### DESCRIPTION

The Test-NxtStringInFile function searches for a specified string or regex pattern within a file and returns a Boolean result.
It supports regular expression searches, case-insensitive searches, and can handle different file encodings.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTStringInFile -Path 'C:\Temp\test.txt' -Query 'Hello World' -PatternType 'Exact'
```

Searches for the exact string 'Hello World' in the file 'C:\Temp\test.txt'.

### INPUTS

System.IO.FileInfo - The file to search in.

### OUTPUTS

System.Boolean - Returns true if the string or pattern is found in the file, otherwise false.

### PARAMETERS

#### -Path

The path to the file to search in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Query

The query string to search for in the file.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PatternType

The type of pattern to use for the search. Can be 'Exact', 'Wildcard', or 'Regex'.

|Property|Value|
|:---|:---|
|Type:|StringCompareOperator|
|Enum values:|Equals, Contains, StartsWith, EndsWith, Wildcard, Regex|
|Position:|Named|
|Default value:|Wildcard|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CaseSensitive

Specifies whether the search should be case-sensitive.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Test-NXTUiLightTheme

Checks if the current UI theme is light.

### SYNTAX

```PowerShell
Test-NXTUiLightTheme
    [[-Identity] <IdentityReference>]
    [<CommonParameters>]
```

### DESCRIPTION

Checks if the current UI theme is light by checking the registry keys for the light theme settings.
Will try to read the 'AppsUseLightTheme' and 'SystemUsesLightTheme' registry values.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTUiLightTheme
```

Checks if the current UI theme is light and returns a boolean value.

### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

`[System.Boolean]`
### PARAMETERS

#### -Identity

The Identifier (e.g. Sid) of the user to check the theme for. If not specified, the current user will be used.

|Property|Value|
|:---|:---|
|Type:|IdentityReference|
|Position:|0|
|Default value:|[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Test-NXTXmlNode

Tests for the existence of a node in an XML document.

### SYNTAX

```PowerShell
# ParameterSet Path
Test-NXTXmlNode
    [-Path] <string[]>
    -XPath <string>
    [-Encoding <Encoding>]
    [-Force]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Xml
Test-NXTXmlNode
    -XPath <string>
    [-InputObject <XmlNode>]
    [-Force]
    [<CommonParameters>]
```

### DESCRIPTION

Tests for the existence of a node in an XML document. The node is located at the specified XPath location.

### EXAMPLES

#### Example 1

```PowerShell
Test-NXTXmlNode -Path 'C:\Temp\test.xml' -XPath '/root/parent[@attribute="value"]/child'
```

Tests if the specified node exists in the XML file at the specified path.

### INPUTS

System.Xml.XmlDocument[] - The XML document(s) to test the node in.

System.IO.FileInfo[] - The XML file(s) to test the node in.

### OUTPUTS

`[System.Boolean]`
### PARAMETERS

#### -Path

The path to the XML file(s) to test the node in.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when writing and reading the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|$OutputEncoding|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -InputObject

The XML node(s) to test the node in.

|Property|Value|
|:---|:---|
|Type:|XmlNode|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -XPath

The XPath to the node to test the node in.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be included when resolving the Path parameter.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Uninstall-NXTApplication

Uninstalls an application based on the neo42 logic.

### SYNTAX

```PowerShell
# ParameterSet ManualExitCodes
Uninstall-NXTApplication
    [-Target] <string>
    [-UninstallKey <string>]
    [-Method <DeploymentMethod>]
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-SuccessExitCodes <int[]>]
    [-RebootExitCodes <int[]>]
    [-ExitOnProcessFailure]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet PackageIgnoreExitCodes
Uninstall-NXTApplication
    [-Package] <NxtRegisteredPackage>
    -IgnoreExitCodes
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet PackageExitCodes
Uninstall-NXTApplication
    [-Package] <NxtRegisteredPackage>
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-SuccessExitCodes <int[]>]
    [-RebootExitCodes <int[]>]
    [-ExitOnProcessFailure]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ApplicationIgnoreExitCodes
Uninstall-NXTApplication
    [-Application] <InstalledApplication>
    -IgnoreExitCodes
    [-Method <DeploymentMethod>]
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ApplicationExitCodes
Uninstall-NXTApplication
    [-Application] <InstalledApplication>
    [-Method <DeploymentMethod>]
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-SuccessExitCodes <int[]>]
    [-RebootExitCodes <int[]>]
    [-ExitOnProcessFailure]
    [-NoCache]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ManualIgnoreExitCodes
Uninstall-NXTApplication
    [-Target] <string>
    -IgnoreExitCodes
    [-UninstallKey <string>]
    [-Method <DeploymentMethod>]
    [-ArgumentList <string[]>]
    [-AdditionalArgumentList <string[]>]
    [-CacheDirectory <string>]
    [-Awaiter <INxtAwaiter[]>]
    [-LogFileName <string>]
    [-NoCache]
    [<CommonParameters>]
```

### DESCRIPTION

Contains all installer specific code to uninstall an application.
Supports multiple parameter sets to allow for different types of application definitions.

### EXAMPLES

#### Example 1

```PowerShell
Uninstall-NXTApplication -Target 'C:\Temp\test.msi' -ArgumentList '/quiet /norestart' -Method MSI
```

Uninstalls the application using the MSI method with the specified arguments.

#### Example 2

```PowerShell
Get-ADTApplication -Name 'Test' | Uninstall-NXTApplication
```

Uninstalls the application using a application object.

#### Example 3

```PowerShell
Get-NXTRegisteredPackage -PackageId '{0420EDC6-CF5E-4C88-8D5E-B81A5E7F3D6A}' | Uninstall-NXTApplication
```

Uninstalls the application using a registered package object.

### INPUTS

PSADTNXT.Package.NxtRegisteredPackage - The registered package to use for the uninstallation.

PSADT.Types.InstalledApplication - The installed application to use for the uninstallation.

System.IO.FileInfo - The file to use for the uninstallation.

### OUTPUTS

PSADT.ProcessManagement.ProcessResult - The result of the uninstallation process.

### PARAMETERS

#### -Target

The path to the uninstaller file.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -UninstallKey

The full path to the uninstall key that this invocation uninstalls. Used for collection information about the uninstall process.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Method

The method to use for the uninstallation.

|Property|Value|
|:---|:---|
|Type:|DeploymentMethod|
|Enum values:|Setup, Copy, MSI, InnoSetup, Nullsoft, BitRockInstaller, Burn, AppX|
|Position:|Named|
|Default value:|Setup|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ArgumentList

The arguments to pass to the uninstaller.
If not specified, the default arguments for the method will be used.
Be aware that arguments are automatically escaped to ensure that they are properly formatted for the process start.
Manual escaping will be passed as a literal string to the process.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -AdditionalArgumentList

The additional arguments to pass to the uninstaller.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CacheDirectory

The package directory to use for the uninstallation.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|(& $script:CommandTable.'Get-ADTSession').NXT.Package.Directory|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Awaiter

Optional awaiter objects that should be evaluated post uninstallation.

|Property|Value|
|:---|:---|
|Type:|INxtAwaiter[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LogFileName

The path to the log file ending with a .log extension.
This file will reside in the log directory of the ADT session.
The resulting full path is available as %LogFile% in the ArgumentList.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|ID.$deploymentTimestamp.log|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -SuccessExitCodes

The exit codes that indicate a successful uninstallation.

|Property|Value|
|:---|:---|
|Type:|Int32[]|
|Position:|Named|
|Default value:| - Defaults depend on the method and session configuration.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -RebootExitCodes

The exit codes that indicate a reboot is required after the uninstallation.

|Property|Value|
|:---|:---|
|Type:|Int32[]|
|Position:|Named|
|Default value:| - Defaults depend on the method and session configuration.|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -IgnoreExitCodes

Determines if the function should ignore exit codes and not treat them as errors.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -NoCache

Determines if the function should avoid using cached uninstaller files.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -ExitOnProcessFailure

Determines if the function should exit with an error if the process fails. If this parameter is specified, the deployment will be aborted.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Update-NXTDetectionStatus

Invokes the session's application detection and updates the detection status accordingly.


### SYNTAX

```PowerShell
Update-NXTDetectionStatus
    [[-ADTSession] <NxtDeploymentSession>]
    [<CommonParameters>]
```

### DESCRIPTION


### INPUTS

**This function does not take any pipeline input.**

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

**This function does not have any documented parameters.**
## Update-NXTTextInFile

Updates text within a file by replacing specified strings.

### SYNTAX

```PowerShell
# ParameterSet Path
Update-NXTTextInFile
    [-Path] <string[]>
    [-Query] <string>
    [-Value] <string>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Regex]
    [-CaseSensitive]
    [-Count <uint32>]
    [-Encoding <Encoding>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet LiteralPath
Update-NXTTextInFile
    [-Query] <string>
    [-Value] <string>
    -LiteralPath <string[]>
    [-Filter <string>]
    [-Exclude <string[]>]
    [-Include <string[]>]
    [-Regex]
    [-CaseSensitive]
    [-Count <uint32>]
    [-Encoding <Encoding>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

### DESCRIPTION

This cmdlet allows you to replace specific text in a file. It searches for a given string and replaces it with another string.
The function can target a specific number of occurrences and use various encoding options.

### EXAMPLES

#### Example 1

```PowerShell
`Update-NXTTextInFile -Path 'C:\Temp\test.txt' -Query 'Hello' -Value 'Hi'`
```

Updates the text 'Hello' to 'Hi' in the file 'C:\Temp\test.txt'.

### INPUTS

System.String - The value to replace the query string with.

### OUTPUTS

**This function does not return any output.**

### PARAMETERS

#### -Path

The path to the file(s) to update.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -LiteralPath

The literal path to the file(s) to update.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Filter

A filter to qualify the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Exclude

A filter to exclude items from the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Include

A filter to include items in the Path parameter.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Query

The string to search for in the file(s).

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|1|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Value

The string to replace the query string with.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|2|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue)|
|Accept wildcard characters:|False|

#### -Regex

Indicates that the query string is a regular expression.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -CaseSensitive

Indicates that the search should be case-sensitive.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Count

The maximum number of occurrences to replace.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|Named|
|Default value:|[System.Int32]::MaxValue|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Encoding

The encoding to use when reading and writing the file. If not specified, the encoding will be detected from the file.

|Property|Value|
|:---|:---|
|Type:|Encoding|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Force

Determines if hidden files should be processed or if the Read-Only attribute should be ignored when setting the content of the file.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTFileNotInUse

Wait until a file is no longer in use by another process.

### SYNTAX

```PowerShell
Wait-NXTFileNotInUse
    [-Path] <string>
    [-Timeout <timespan>]
    [<CommonParameters>]
```

### DESCRIPTION

Wait until a file is no longer in use by another process.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTFileNotInUse -Path 'C:\Temp\file.txt' -Timeout '00:02:00'
```

Wait until the file 'C:\Temp\file.txt' is no longer in use by another process or until the timeout of 120 seconds is reached.

### INPUTS

System.IO.FileInfo - The file to check.

### OUTPUTS

System.Boolean - Returns true if the file is no longer in use, otherwise false.

### PARAMETERS

#### -Path

The path to the file to check.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the file to be released.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTFileSystem

Monitors the presence of a specified path within a set timeout period.

### SYNTAX

```PowerShell
Wait-NXTFileSystem
    [-Path] <string>
    [-Timeout <timespan>]
    [-PassThru]
    [<CommonParameters>]
```

### DESCRIPTION

This function checks for the existence of a specified file or folder within a given time frame.
It continuously checks for the existence until the timeout is reached.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTFileSystem -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00'
```

Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to appear.

### INPUTS

System.IO.FileSystemInfo - The filesystem object to monitor.

### OUTPUTS

System.Boolean - Returns true if the path appears within the timeout period, otherwise false.

System.IO.FileSystemInfo - Returns the file system object if PassThru is specified

### PARAMETERS

#### -Path

The path to the file or directory to monitor.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the file to appear.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Instead of returning a boolean, return the object.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTFileSystemIsRemoved

Monitors the removal of a specified file within a set timeout period.

### SYNTAX

```PowerShell
Wait-NXTFileSystemIsRemoved
    [-Path] <string>
    [-Timeout <timespan>]
    [<CommonParameters>]
```

### DESCRIPTION

This function checks for the disappearance of a specified file within a given time frame.
It continuously monitors the file's presence until the file is removed or the timeout is reached.
The function also supports the resolution of CMD environment variables in the file path.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTFileSystemIsRemoved -Path "C:\Temp\Sources\Installer.exe" -Timeout '00:02:00'
```

Monitors for 'Installer.exe' in the specified directory and waits up to 120 seconds for it to disappear.

### INPUTS

System.IO.FileSystemInfo - The filesystem object to monitor.

### OUTPUTS

System.Boolean - Returns true if the file is removed within the timeout period, otherwise false.

### PARAMETERS

#### -Path

The path to the file or directory to monitor.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the file to be removed.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTProcess

Monitors the startup of a specified process within a set timeout period.

### SYNTAX

```PowerShell
# ParameterSet Name
Wait-NXTProcess
    [-Name] <string>
    [-Timeout <timespan>]
    [-PassThru]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Id
Wait-NXTProcess
    -Id <uint32>
    [-Timeout <timespan>]
    [-PassThru]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ProcessDefinition
Wait-NXTProcess
    -ProcessDefinition <ProcessDefinition>
    [-Timeout <timespan>]
    [-PassThru]
    [<CommonParameters>]
```

### DESCRIPTION

This function checks for the startup of a process.
The function continuously checks for the process's presence until it starts or the timeout is reached.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTProcess -Name "notepad.exe" -Timeout '00:02:00'
```

Monitors for 'notepad.exe' to start and waits up to 120 seconds for it to appear.

### INPUTS

System.String - The name of the process to monitor.

System.UInt32 - The process ID to monitor.

System.Diagnostics.Process - The process to monitor.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.

### OUTPUTS

System.Boolean - Returns true if the process starts within the timeout period, otherwise false.

System.Diagnostics.Process - Returns the process if PassThru is specified

### PARAMETERS

#### -Name

The name of the process to monitor.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Id

The ID of the process to monitor.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -ProcessDefinition

The process definition to monitor.

|Property|Value|
|:---|:---|
|Type:|ProcessDefinition|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the process to start.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Instead of returning a boolean, return the object.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTProcessIsStopped

Monitors the termination of a specified process within a set timeout.

### SYNTAX

```PowerShell
# ParameterSet Name
Wait-NXTProcessIsStopped
    [-Name] <string>
    [-Timeout <timespan>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet Id
Wait-NXTProcessIsStopped
    -Id <uint32>
    [-Timeout <timespan>]
    [<CommonParameters>]
```

```PowerShell
# ParameterSet ProcessDefinition
Wait-NXTProcessIsStopped
    -ProcessDefinition <ProcessDefinition>
    [-Timeout <timespan>]
    [<CommonParameters>]
```

### DESCRIPTION

This function checks for the termination of a process within a specified time frame.
The function continuously monitors the process's presence until it stops or the timeout is reached.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTProcessIsStopped -Name "notepad.exe" -Timeout '00:02:00'
```

This example monitors for 'notepad.exe' and waits up to 120 seconds for it to stop.

### INPUTS

System.String - The name of the process to monitor.

System.UInt32 - The process ID to monitor.

System.Diagnostics.Process - The process to monitor.

Microsoft.Management.Infrastructure.CimInstance - The Win32_Process cim instance to monitor.

PSADT.ProcessManagement.ProcessDefinition - The process definition to monitor.

PSADT.ProcessManagement.RunningProcess - The running process to monitor.

PSADTNXT.ProcessManagement.NxtCloseProcess - The process definition to stop.

### OUTPUTS

System.Boolean - Returns true if the process is terminated within the timeout period, otherwise false.

### PARAMETERS

#### -Name

The name of the process to monitor.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Id

The process ID to monitor. Can be a single ID or an array of IDs.

|Property|Value|
|:---|:---|
|Type:|UInt32|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -ProcessDefinition

The process definition object to monitor.

|Property|Value|
|:---|:---|
|Type:|ProcessDefinition|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByValue, ByPropertyName)|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the process to stop.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTRegistryKey

Watches a specified registry key for a given duration.

### SYNTAX

```PowerShell
Wait-NXTRegistryKey
    [-Key] <string[]>
    [-Wow6432Node]
    [-Timeout <timespan>]
    [-PassThru]
    [<CommonParameters>]
```

### DESCRIPTION

This command monitors a specified registry key and checks for its existence within a defined timeout period.
It is useful for scenarios where the presence of a registry key is required for certain processes or checks.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTRegistryKey -Key "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
```

This example monitors the specified registry key and waits up to 60 seconds to check its existence.

### INPUTS

Microsoft.Win32.RegistryKey - The registry key to monitor.

### OUTPUTS

System.Boolean - Returns true if the registry key exist within the timeout period, otherwise false.

Microsoft.Win32.RegistryKey - Returns the registry key if PassThru was specified

### PARAMETERS

#### -Key

The path to the registry key to monitor.

|Property|Value|
|:---|:---|
|Type:|String[]|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Wow6432Node

Specifies that the registry key is located in the Wow6432Node.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the registry key to be created.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -PassThru

Instead of returning a boolean, return the object.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

## Wait-NXTRegistryKeyIsRemoved

Watches a specified registry key for a given duration.

### SYNTAX

```PowerShell
Wait-NXTRegistryKeyIsRemoved
    [-Key] <string>
    [-Wow6432Node]
    [-Timeout <timespan>]
    [<CommonParameters>]
```

### DESCRIPTION

This command monitors a specified registry key and checks for its existence within a defined timeout period.
It is useful for scenarios where the presence of a registry key is required for certain processes or checks.

### EXAMPLES

#### Example 1

```PowerShell
Wait-NXTRegistryKeyIsRemoved -Path "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
```

This example monitors the specified registry key and waits up to 60 seconds to check its existence has ended.

### INPUTS

Microsoft.Win32.RegistryKey - The registry key to monitor.

### OUTPUTS

System.Boolean - Returns true if the registry key(s) exist within the timeout period, otherwise false.

### PARAMETERS

#### -Key

The path to the registry key(s) to monitor. Can be a single key or an array of keys.

|Property|Value|
|:---|:---|
|Type:|String|
|Position:|0|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|True (ByPropertyName)|
|Accept wildcard characters:|False|

#### -Wow6432Node

Specifies that the registry key is located in the Wow6432Node.

|Property|Value|
|:---|:---|
|Type:|SwitchParameter|
|Position:|Named|
|Default value:|None|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|

#### -Timeout

The maximum time to wait for the registry key(s) to be created.

|Property|Value|
|:---|:---|
|Type:|TimeSpan|
|Position:|Named|
|Default value:|00:01:00|
|Required:|False|
|Accept pipeline input:|False|
|Accept wildcard characters:|False|


