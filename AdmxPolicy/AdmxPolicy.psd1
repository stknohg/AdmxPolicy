#
# Module manifest
#
@{
    GUID = 'b05e2e20-3743-443a-b977-5e0b93b418b4'
    ModuleVersion = '0.2'
    Description = 'Get group policy information from ADMX files.(Beta)'

    Author = 'stknohg'
    CompanyName = 'stknohg'
    Copyright = '(c) 2017 stknohg. All rights reserved.'

    PowerShellVersion = '2.0'
    NestedModules = @('AddTypes.psm1', 'AdmxPolicy.psm1')
    # TypesToProcess = @()
    FormatsToProcess = @('AdmxPolicy.format.ps1xml')
    FunctionsToExport = @('Get-AdmlResource', 'Get-AdmxFileInfo', 'Get-AdmxPolicies')
    #AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/stknohg/AdmxPolicy'
            LicenseUri = 'https://github.com/stknohg/AdmxPolicy/blob/master/LICENSE'
            # IconUri = ''
            # ReleaseNotes = ''
            Tags = @('GroupPolicy', 'Admx', 'Adml')
        }
    }
}