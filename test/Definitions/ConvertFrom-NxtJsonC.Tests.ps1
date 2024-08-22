Describe "ConvertFrom-NxtEncodedObject" {
    Context "When given an input" {
        BeforeAll {
            [string]$jsonC = @'
{
    "terminal.integrated.profiles.windows": {
        //Update Blabla
        "Command Prompt": {
            "path": [
                "${env:windir}\\Sysnative\\cmd.exe", //Blabla2
                "${env:windir}\\System32\\cmd.exe"
            ]
        }, /*
        Multiline Blabla
        */
        "Git Bash": {
            "source": "Git Bash"
        },
        "Windows PowerShell": {
            "path": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
        } /* Multiline Blabla2 */
    },
    "powershell.powerShellAdditionalExePaths": {
        "pwsh7": "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
        "pwsh5": "C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
    },/*,
	"powershell.powerShellDefaultVersion": "pwsh5",
	*/
    "powershell.powerShellDefaultVersion": "pwsh7",
    "[powershell]": {
        "editor.wordSeparators": "`~!@#$%^&*()=+[{]}\\|;:'\",.<>/?"
    },
    "testCommentIndicators": {
        "lineComment": "//",
        "blockComment": [
            "/*",
            "*/"
        ]
    },
    "test": true/*test*/
}
'@
        }
        It "Should return expected output" {
            $output = ConvertFrom-NxtJsonC -InputObject $jsonC
            $output | Should -BeOfType PSCustomObject
            $output."update.mode" | Should -Be 'none'
            $output."terminal.integrated.profiles.windows"."Command Prompt" | Should -Not -BeNullOrEmpty
            $output."terminal.integrated.profiles.windows"."Git Bash" | Should -Not -BeNullOrEmpty
            $output."terminal.integrated.profiles.windows"."Windows PowerShell".path | Should -Not -BeNullOrEmpty
            $output."powershell.powerShellDefaultVersion" | Should -Be "pwsh7"
            $output.test | Should -Be $true

        }
        It "Should fail when given an invalid input" {
            { ConvertFrom-NxtJsonC -InputObject 'invalid' } | Should -Throw
        }
        It "Should accept different methods of inputing the object" {
            $output = ConvertFrom-NxtJsonC -InputObject $jsonC
            $output | Should -BeOfType PSCustomObject
            $output."update.mode" | Should -Be 'none'
            $output = $jsonC | ConvertFrom-NxtJsonC
            $output | Should -BeOfType PSCustomObject
            $output."update.mode" | Should -Be 'none'
            $output = ConvertFrom-NxtJsonC $jsonC
            $output | Should -BeOfType PSCustomObject
            $output."update.mode" | Should -Be 'none'
        }
        It "Should not match comment indicators in values" {
            $output = ConvertFrom-NxtJsonC -InputObject $jsonC
            $output | Should -BeOfType PSCustomObject
            $output.testCommentIndicators.lineComment | Should -Be '//'
            $output.testCommentIndicators.blockComment[0] | Should -Be '/*'
            $output.testCommentIndicators.blockComment[1] | Should -Be '*/'
        }
    }
}
