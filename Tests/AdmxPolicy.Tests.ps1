Import-Module Pester
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "\AdmxPolicy") -Force

Describe "Get-AdmlResource" {
    It "if the adml file was not found, throw exception." { 
        ({ Get-AdmlResource -FilePath ".\admx\notfound.adml" }) | Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmlResource -FilePath ".\admx\InvalidExtension.admz" }) | Should throw "must be .adml file."
    }
    It "get correct string messages." {
        $resource = Get-AdmlResource -FilePath ".\admx\ja-JP\ActiveXInstallService.adml"
        $resource.DisplayName | Should Be "ActiveX Installer Service"
        $resource.Description | Should Be "承認されたインストール サイトから ActiveX コントロールをインストールする"
        $resource.Strings.Count | Should Be 8
        $resource.Strings["TrustedZonePrompt"]  | Should Be "ユーザーに確認する"
    }
}

Describe "Get-AdmxFileInfo" {
    It "if the admx file was not found, throw exception." { 
        ({ Get-AdmxFileInfo -FilePath ".\admx\notfound.admx" }) | Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmxFileInfo -FilePath ".\admx\InvalidExtension.admz" }) | Should throw "must be .admx file."
    }
    It "get correct file information." {
        $fileInfo = Get-AdmxFileInfo -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP"
        $fileInfo.Name | Should Be "ActiveXInstallService.admx"
        $fileInfo.DisplayName | Should Be "ActiveX Installer Service"
        $fileInfo.Description | Should Be "承認されたインストール サイトから ActiveX コントロールをインストールする"
        $fileInfo.Categories.Count | Should Be 1
        $fileInfo.Categories[0].Name | Should Be "AxInstSv"
    }
}

Describe "Get-AdmxPolicies" {
    It "if the admx file was not found, throw exception." { 
        ({ Get-AdmxPolicies -FilePath ".\admx\notfound.admx" }) | Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmxPolicies -FilePath ".\admx\InvalidExtension.admz" }) | Should throw "must be .admx file."
    }
    It "get correct policy counts." {
        $policies = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP"
        $policies.Count | Should Be 2
    }
    It "get correct policy information." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy | Should Not BeNullOrEmpty
        $policy.DisplayName | Should Be "ActiveX コントロールの承認されたインストール サイト"
        $policy.RegistryType | Should Be LocalMachine
        $policy.RegistryDrives.Count | Should Be 1
        $policy.RegistryDrives[0] | Should Be "HKLM:"
        $policy.RegistryPath | Should Be "SOFTWARE\Policies\Microsoft\Windows\AxInstaller"
    }
    # tests for a single value
    It "if a policy doesn't have EnabledValue/DisabledValue, each property value is null." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "AxISURLZonePolicies"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.RegistryValueName | Should BeNullOrEmpty
        $policy.ValueInfo.EnabledValue | Should BeNullOrEmpty
        $policy.ValueInfo.DisabledValue | Should BeNullOrEmpty
    }
    It "get correct RegistryValueName/EnabledValue/DisabledValue." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.RegistryValueName | Should Be "ApprovedList"
        $policy.ValueInfo.EnabledValue.Type | Should Be Decimal
        $policy.ValueInfo.EnabledValue.Value | Should Be 1
        $policy.ValueInfo.DisabledValue.Type | Should Be Decimal
        $policy.ValueInfo.DisabledValue.Value | Should Be 0
    }
    # tests for list values.
    It "if a policy doesn't have EnabledList/DisabledList, each property value is null." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasEnabledList | Should Be $false
        $policy.ValueInfo.EnabledList | Should BeNullOrEmpty
        $policy.ValueInfo.HasDisabledList | Should Be $false
        $policy.ValueInfo.DisabledList | Should BeNullOrEmpty
    }
    It "get correct EnabledList/DisabledList value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\DiskDiagnostic.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "WdiScenarioExecutionPolicy"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasEnabledList | Should Be $true
        $policy.ValueInfo.EnabledList.Items.Count | Should Be 2
        $policy.ValueInfo.EnabledList.Items[1].RegistryPath | Should Be "SOFTWARE\Policies\Microsoft\Windows\WDI\{29689E29-2CE9-4751-B4FC-8EFF5066E3FD}"
        $policy.ValueInfo.EnabledList.Items[1].RegistryValueName | Should Be "EnabledScenarioExecutionLevel"
        $policy.ValueInfo.EnabledList.Items[1].Value.Value | Should Be 2
        $policy.ValueInfo.HasDisabledList | Should Be $true
        $policy.ValueInfo.DisabledList.Items.Count | Should Be 2
        $policy.ValueInfo.DisabledList.Items[1].RegistryPath | Should Be "SOFTWARE\Policies\Microsoft\Windows\WDI\{29689E29-2CE9-4751-B4FC-8EFF5066E3FD}"
        $policy.ValueInfo.DisabledList.Items[1].RegistryValueName | Should Be "EnabledScenarioExecutionLevel"
        $policy.ValueInfo.DisabledList.Items[1].Value.Value | Should Be 1
    }
    # tests for Elements values.
    It "if a policy doesn't have Elements, each property value is null." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\DiskDiagnostic.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "WdiScenarioExecutionPolicy"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $false
        $policy.ValueInfo.Elements | Should BeNullOrEmpty
    }
    It "get correct Boolean element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "AxISURLZonePolicies"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "IgnoreUnknownCA" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "Boolean"
        $element.RegistryPath | Should Be ""
        $element.RegistryValueName | Should Be "IgnoreUnknownCA"
        $element.TrueValue.Type | Should Be "Decimal"
        $element.TrueValue.Value | Should Be 1
        $element.FalseValue.Type | Should Be "Decimal"
        $element.FalseValue.Value | Should Be 0
    }
    It "get correct Decimal element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\DFS.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "DFSDiscoverDC"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "DFSDiscoverDialog" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "Decimal"
        $element.RegistryPath | Should Be ""
        $element.RegistryValueName | Should Be "DfsDcNameDelay"
        $element.MinValue | Should Be 15
        $element.MaxValue | Should Be 360
        $element.StoreAsText | Should Be $false
        $element.Soft | Should Be $false
    }
    # LongDecial doesn't exists?
    It "get correct Text element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\DiskDiagnostic.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "DfdAlertPolicy"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "DfdAlertPolicyTitle" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "Text"
        $element.RegistryPath | Should Be ""
        $element.RegistryValueName | Should Be "DfdAlertTextOverride"
        $element.Required | Should Be $true
        $element.MaxLength | Should Be 512
        $element.Expandable | Should Be $false
        $element.Soft | Should Be $false
    }
    It "get correct MultiText element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\CipherSuiteOrder.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "SSLCurveOrder"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "SSLCurveOrderList" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "MultiText"
        $element.RegistryPath | Should Be ""
        $element.RegistryValueName | Should Be "EccCurves"
        $element.Required | Should Be $false
        $element.MaxLength | Should Be 1023
        $element.MaxStrings | Should Be 0
        $element.Soft | Should Be $false
    }
    It "get correct Enum element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "AxISURLZonePolicies"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "InstallTrustedOCX" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "Enum"
        $element.RegistryPath | Should Be ""
        $element.RegistryValueName | Should Be "InstallTrustedOCX"
        $element.Enums.Count | Should Be 3
        $element.Enums[0].Key | Should Be "インストールしない"
        $element.Enums[0].Value.Type | Should Be "Decimal"
        $element.Enums[0].Value.Value | Should Be 0
        $element.Enums[1].Key | Should Be "ユーザーに確認する"
        $element.Enums[1].Value.Type | Should Be "Decimal"
        $element.Enums[1].Value.Value | Should Be 1
        $element.Enums[2].Key | Should Be "警告なしにインストールする"
        $element.Enums[2].Value.Type | Should Be "Decimal"
        $element.Enums[2].Value.Value | Should Be 2
    }
    It "get correct List element value." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.HasElements | Should Be $true
        $element = $policy.ValueInfo.Elements.Items | Where-Object { $_.Id -eq "ApprovedActiveXInstallSiteslist" }
        $element | Should Not BeNullOrEmpty
        $element.ElementType | Should Be "List"
        $element.RegistryPath | Should Be "SOFTWARE\Policies\Microsoft\Windows\AxInstaller\ApprovedActiveXInstallSites"
        $element.RegistryValueName | Should Be ""
        $element.ValuePrefix | Should Be ""
        $element.Additive | Should Be $true
        $element.Expandable | Should Be $false
        $element.ExplicitValue | Should Be $true
        $element.ClientExtension | Should Be ""
    }
}
