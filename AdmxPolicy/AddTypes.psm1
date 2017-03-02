#requires -Version 2.0
Set-Strictmode -Version 2.0
# load AdmxPolicy classes
# In PowerShell 2.0, this file must be loaded first.
$RootPath = Split-path $script:MyInvocation.MyCommand.Path -Parent
Add-Type -Path (Join-Path $RootPath "AdmxPolicy.cs")
