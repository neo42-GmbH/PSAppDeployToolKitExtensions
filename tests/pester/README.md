# Pester tests guide

## Preparation
Use `Initialize-PesterPsadtEnvironment.ps1` to import the PSADT modules and the Pester module and to load the PSADTNXT environment for the current session.

Use `support-scripts\Compare-FunctionsAndTests.ps1` to compare and create missing test files.

## Running tests
Tests can be run by
- using the editor inline command 'Run tests' above the start of the `Descripe` block
- invoking the script file `<project root>\.tools\Invoke-PesterTests.ps1`.

## Function tests list
- Test all input options
  - Parameters (named is enough)
  - Pipeline passthru
  - For each input option
    - Positive result
    - Negative result
    - null/empty/zero-string
    - Invalid data type
    - Alias
- Test all output options (if more than one)
