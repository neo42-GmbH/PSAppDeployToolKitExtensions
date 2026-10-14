# Pester tests guide

## Preparation
Use `<project root>\.tools\Compare-PesterTestAndFunction.ps1` to compare and create missing test files.

## Running tests
Tests can be run by
- using the editor inline command 'Run tests'
- invoking the script file `<project root>\.tools\Invoke-PesterTest.ps1`.

## Function tests list
- Test all input options
  - Parameters (named is enough)
  - Pipeline passthru
  - For each input option
    - Positive result
    - Negative result
    - null/empty
    - Invalid data type
- Test all output options
