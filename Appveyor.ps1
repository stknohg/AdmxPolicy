# import module
$RootPath = Join-Path $PSScriptRoot 'AdmxPolicy'
Import-Module (Join-Path $RootPath 'AdmxPolicy.psd1') -Force

# invoke all tests
$TestRootPath = Join-Path $PSScriptRoot 'AdmxPolicy.Tests'
$TestOutputPath = '.\TestsResults.xml'
Set-Location -LiteralPath $TestRootPath
$result = Invoke-Pester -Path $TestRootPath -OutputFormat NUnitXml -OutputFile $TestOutputPath -PassThru
if ($null -ne $env:APPVEYOR_JOB_ID) {
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $TestOutputPath))
}
if ($result.FailedCount -gt 0) { 
    throw "$($result.FailedCount) tests failed."
}
