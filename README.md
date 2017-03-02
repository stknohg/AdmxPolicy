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
Get-AdmxFileInfo -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx"
```

### Get-AdmxPolicies

Get group policy information from an ADMX file.

```ps1
Get-AdmxPolicies -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx"
```

## License

MIT