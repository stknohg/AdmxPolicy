#requires -Version 2.0
Set-Strictmode -Version 2.0
# load AdmxPolicy classes
# In PowerShell 2.0, this file must be loaded first.
$RootPath = Split-path $script:MyInvocation.MyCommand.Path -Parent
if ( $PSVersionTable.PSVersion.Major -lt 5.0 ) {
    # PowerShell 2.0 - 4.0 dosen't have System.Management.Automation.HiddenAttribute .
    Add-Type -TypeDefinition ((Get-Content (Join-Path $RootPath "AdmxPolicy.cs") -Encoding UTF8) -join "`r`n").Replace('[System.Management.Automation.HiddenAttribute]','')
} else {
    Add-Type -Path (Join-Path $RootPath "AdmxPolicy.cs")
}
