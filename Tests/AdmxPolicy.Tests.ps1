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

Pester\Describe "Get-AdmxFileInfo" {
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

Pester\Describe "Get-AdmxPolicies" {
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
        $policy.RegistryPath.Count | Should Be 1
        $policy.RegistryPath[0] | Should Be "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AxInstaller"
    }
    It "if a policy don't have EnabledValue/DisabledValue, each property value is null." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "AxISURLZonePolicies"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.RegistryValueName | Should BeNullOrEmpty
        $policy.ValueInfo.EnabledValue | Should BeNullOrEmpty
        $policy.ValueInfo.DisabledValue | Should BeNullOrEmpty
    }
    It "get correct RegistryValueName/EnabledValue/DisabledValue" {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy.ValueInfo | Should Not BeNullOrEmpty
        $policy.ValueInfo.RegistryValueName | Should Be "ApprovedList"
        $policy.ValueInfo.EnabledValue.Type | Should Be Decimal
        $policy.ValueInfo.EnabledValue.Value | Should Be 1
        $policy.ValueInfo.DisabledValue.Type | Should Be Decimal
        $policy.ValueInfo.DisabledValue.Value | Should Be 0
    }
}
