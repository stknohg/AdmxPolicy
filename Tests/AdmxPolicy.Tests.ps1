Import-Module Pester
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "\AdmxPolicy") -Force

Pester\Describe "Get-AdmlResource" {
    It "if the adml file was not found, throw exception." { 
        ({ Get-AdmlResource -FilePath ".\admx\notfound.adml" }) | Pester\Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmlResource -FilePath ".\admx\InvalidExtension.admz" }) | Pester\Should throw "must be .adml file."
    }
    It "get correct string messages." {
        $resource = Get-AdmlResource -FilePath ".\admx\ja-JP\ActiveXInstallService.adml"
        $resource.DisplayName | Pester\Should Be "ActiveX Installer Service"
        $resource.Description | Pester\Should Be "承認されたインストール サイトから ActiveX コントロールをインストールする"
        $resource.Strings.Count | Pester\Should Be 8
        $resource.Strings["TrustedZonePrompt"]  | Pester\Should Be "ユーザーに確認する"
    }
}

Pester\Describe "Get-AdmxFileInfo" {
    It "if the admx file was not found, throw exception." { 
        ({ Get-AdmxFileInfo -FilePath ".\admx\notfound.admx" }) | Pester\Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmxFileInfo -FilePath ".\admx\InvalidExtension.admz" }) | Pester\Should throw "must be .admx file."
    }
    It "get correct file information." {
        $fileInfo = Get-AdmxFileInfo -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP"
        $fileInfo.Name | Pester\Should Be "ActiveXInstallService.admx"
        $fileInfo.DisplayName | Pester\Should Be "ActiveX Installer Service"
        $fileInfo.Description | Pester\Should Be "承認されたインストール サイトから ActiveX コントロールをインストールする"
        $fileInfo.Categories.Count | Pester\Should Be 1
        $fileInfo.Categories[0].Name | Pester\Should Be "AxInstSv"
    }
}

Pester\Describe "Get-AdmxPolicies" {
    It "if the admx file was not found, throw exception." { 
        ({ Get-AdmxPolicies -FilePath ".\admx\notfound.admx" }) | Pester\Should throw "not found."
    }
    It "if the file extension was invalid, throw exception." { 
        ({ Get-AdmxPolicies -FilePath ".\admx\InvalidExtension.admz" }) | Pester\Should throw "must be .admx file."
    }
    It "get correct policy counts." {
        $policies = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP"
        $policies.Count | Pester\Should Be 2
    }
    It "get correct policy information." {
        $policy = Get-AdmxPolicies -FilePath ".\admx\ActiveXInstallService.admx" -CultureName "ja-JP" `
                    | Where-Object { $_.Name -eq "ApprovedActiveXInstallSites"}
        $policy | Pester\Should Not BeNullOrEmpty
        $policy.DisplayName | Pester\Should Be "ActiveX コントロールの承認されたインストール サイト"
        $policy.RegistryType | Pester\Should Be LocalMachine
        $policy.RegistryPath.Count | Pester\Should Be 1
        $policy.RegistryPath[0] | Pester\Should Be "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AxInstaller"
    }
}
