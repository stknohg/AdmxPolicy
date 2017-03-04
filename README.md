# AdmxPolicy

Get group policy information from ADMX files.  
(Beta version.) 

## How to Install

You can install from [PowerShell Gallery](https://www.powershellgallery.com/packages/AdmxPolicy/).

```ps1
Install-Module -Name AdmxPolicy -Scope CurrentUser
```

## Usage

### Get-AdmxFileInfo

Get ADMX file meta information.

```ps1
Get-AdmxFileInfo -FilePath [ADMX file path]
```

e.g.)

```ps1
PS C:\> Get-AdmxFileInfo -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx" | Format-List


Name        : ActiveXInstallService.admx
DisplayName : ActiveX Installer Service
Description : 承認されたインストール サイトから ActiveX コントロールをインストールする
Categories  : {AxInstSv}
```

### Get-AdmxPolicies

Get group policy information from an ADMX file.

```ps1
Get-AdmxPolicies -FilePath [ADMX file path]
```

e.g.)

```ps1
PS C:\> Get-AdmxPolicies -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx" | Select-Object -First 1 | Format-List


Name           : ApprovedActiveXInstallSites
DisplayName    : ActiveX コントロールの承認されたインストール サイト
ExplainText    : このポリシー設定では、組織の標準ユーザーがコンピューターに ActiveX コントロールをインストールする際に使用できる ActiveX インストール サイトを
                 決定します。この設定が有効になっている場合、管理者は、ホスト URL で指定された、承認された Activex インストール サイトの一覧を作成できます。

                 この設定を有効にした場合、管理者は、ホスト URL で指定された、承認された ActiveX インストール サイトの一覧を作成できます。

                 このポリシー設定を無効にした場合、または構成しなかった場合は、ActiveX コントロールのインストール前に、管理者資格情報を求めるダイアログが表示
                 されます。

                 注: ホスト URL を指定する際に、ワイルドカード文字は使用できません。


RegistryType   : LocalMachine
RegistryDrives : {HKLM:}
RegistryPath   : SOFTWARE\Policies\Microsoft\Windows\AxInstaller
FileName       : ActiveXInstallService.admx
```

## License

MIT