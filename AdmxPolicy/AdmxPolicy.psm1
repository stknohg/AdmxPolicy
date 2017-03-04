﻿#requires -Version 2.0
Set-Strictmode -Version 2.0

<#
.SYNOPSIS
    Get resources from an ADML file.
.DESCRIPTION
    This function reads an ADML file and loads message resources.
.EXAMPLE
    Get-AdmlResource -FilePath "C:\Windows\PolicyDefinitions\ja-JP\ActiveXInstallService.adml"

    Set ADML file path.
#>
function Get-AdmlResource() {
    [OutputType([AdmxPolicy.AdmlResource])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [string]$FilePath,
        [switch]$ForAdmxId = $false,
        [switch]$WithWindowsAdml = $false
    )
    begin {
        Write-Verbose "Start Get-AdmlResource..."
        Write-Verbose "ForAdmxId : $ForAdmxId"
        Write-Verbose "WithWindowsAdml : $WithWindowsAdml"
    }
    process {
        # validation
        Write-Verbose "FilePath : $FilePath"
        if ( -not (Test-Path $FilePath -PathType Leaf) ) {
            throw [IO.FileNotFoundException] "Get-AdmlResource : $FilePath not found."
        }
        if ( [IO.Path]::GetExtension($FilePath) -ne ".adml" ) {
            throw [ArgumentException] "Get-AdmlResource : $FilePath must be .adml file."
        }
        
        # load xml
        try {
            $xml = [xml]((Get-Content -LiteralPath $FilePath -Encoding UTF8))
        } catch {
            Write-Error $_
            return
        }
        
        # displayname / description
        $Result = New-Object "AdmxPolicy.AdmlResource" -ArgumentList ($xml.policyDefinitionResources.displayName, $xml.policyDefinitionResources.description)
        # stringResource
        $strings = $xml.policyDefinitionResources.resources.stringTable.string
        foreach ( $string in $strings ) {
            $id = $string.id
            if ($ForAdmxId) {
                $id = "`$(string.{0})" -f $string.id
            }
            $Result.Strings.Add($id, $string.InnerText)
        }
        # windows AdmlResource
        if ( $WithWindowsAdml ) {
            $windowsAdmlFullName = Join-Path (Split-Path $FilePath -Parent) "windows.adml"
            if ( -not (Test-Path $windowsAdmlFullName -PathType Leaf) ) {
                Write-Warning "$windowsAdmlFullName not found."
            } else {
                $windowsXml = [xml]((Get-Content -LiteralPath $windowsAdmlFullName -Encoding UTF8))
                $strings2 = $windowsXml.policyDefinitionResources.resources.stringTable.string
                foreach ( $string in $strings2 ) {
                    $id = $string.id
                    if ( $ForAdmxId ) {
                        $id = "`$(windows.{0})" -f $string.id
                    }
                    $Result.Windows.Add($id, $string.InnerText)
                }
            }
        }
        return $Result
    }
}

# Private
function GetAdmxFileInfoFromXml ([string]$Name,  [xml]$Xml, [AdmxPolicy.AdmlResource]$AdmlResource) {
    $Result = New-Object "AdmxPolicy.AdmxFileInfo" -ArgumentList ($Name, $AdmlResource.DisplayName, $AdmlResource.Description)
    try {
        $categories = $xml.policyDefinitions.categories.category
        foreach ($category in $categories) {
            $displayName = "" 
            if ( $AdmlResource.Strings.ContainsKey($category.displayName) ) {
                $displayName = $AdmlResource.Strings[$category.displayName]
            }
            $item = New-Object "AdmxPolicy.CategoryInfo" -ArgumentList ($category.name, $displayName)
            $Result.Categories.Add($item)
        }
    } catch {
        # do nothing
    }
    return $Result
}

<#
.SYNOPSIS
    Get ADMX file meta information.
.DESCRIPTION
    This function reads an ADMX file and get meta information.
.EXAMPLE
    Get-AdmxFileInfo -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx"

    Set ADMX file path.
.EXAMPLE
    Get-AdmxFileInfo -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx" -CultureName "ja-JP"

    Specify culture name.
#>
function Get-AdmxFileInfo () {
    [OutputType([AdmxPolicy.AdmxFileInfo])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [string]$FilePath = "",
        [string]$CultureName = ((Get-Culture).Name)
    )
    begin {
        Write-Verbose "Start Get-AdmxFileInfo..."
        Write-Verbose "CultureName : $CultureName"
        # set default
        if ( $CultureName -eq "" ) {
            $CultureName = (Get-Culture).Name
        }
    }
    process {
        # validation
        Write-Verbose "FilePath : $FilePath"
        if ( -not (Test-Path $FilePath -PathType Leaf) ) {
            throw [IO.FileNotFoundException] "Get-AdmxFileInfo : $FilePath not found."
        }
        if ( [IO.Path]::GetExtension($FilePath) -ne ".admx" ) {
            throw [ArgumentException] "Get-AdmxFileInfo : $FilePath must be .admx file."
        }

        # load xml
        try {
            $xml = [xml](Get-Content -LiteralPath $FilePath -Encoding UTF8)
        } catch {
            Write-Error $_
            return
        }

        # get adml resource
        $admlPath = Join-Path (Split-Path $FilePath -Parent) "$($CultureName)\$([IO.Path]::GetFileNameWithoutExtension($FilePath)).adml"
        $admlResource = New-Object "AdmxPolicy.AdmlResource"
        if ( -not (Test-Path -LiteralPath $admlPath) ) {
            Write-Warning "ADML file($admlPath) not found."
        } else {
            $admlResource = Get-AdmlResource -FilePath $admlPath -ForAdmxId:$true
        }

        # get FileInfo
        $Result = GetAdmxFileInfoFromXml -Name ([IO.Path]::GetFileName($FilePath)) -Xml $xml -AdmlResource $admlResource
        Write-Output $Result
    }
}

# Private
function GetValueDefinitionFromXmlNode ([Xml.XmlElement]$ValueElement) {
    $type = [AdmxPolicy.ValueTypes]::Unknown
    $value = $null
    switch ( $ValueElement.FirstChild.Name ) {
        "delete" {
            $type = [AdmxPolicy.ValueTypes]::Delete
            $value = $null
        }
        "decimal" {
            $type = [AdmxPolicy.ValueTypes]::Decimal
            $value = [decimal]$ValueElement.FirstChild.value
        }
        "longdecimal" {
            $type = [AdmxPolicy.ValueTypes]::LongDecimal
            $value = [decimal]$ValueElement.FirstChild.value
        }
        "string" {
            $type = [AdmxPolicy.ValueTypes]::String
            $value = [string]$ValueElement.FirstChild.value
        }
        Default {
            $type = [AdmxPolicy.ValueTypes]::Unknown
            $value = $ValueElement.FirstChild.value
        }
    }
    return New-Object "AdmxPolicy.ValueDefinition" -ArgumentList ($type, $value)
}

# Private 
function GetValueInfoFromXmlNode ([Xml.XmlElement]$PolicyElement) {
    $Result = New-Object "AdmxPolicy.PolicyValueInfo"
    # base value definitions
    $valueName = $null
    if ( $PolicyElement.HasAttribute("valueName") ) {
        $valueName = $PolicyElement.valueName
    }
    $enabledValue = $null
    if ( $PolicyElement.Item("enabledValue") ) {
        $enabledValue = GetValueDefinitionFromXmlNode -ValueElement $PolicyElement.enabledValue
    }
    $disabledValue = $null
    if ( $PolicyElement.Item("disabledValue") ) {
        $disabledValue = GetValueDefinitionFromXmlNode -ValueElement $PolicyElement.disabledValue
    }
    $Result.set_RegistryValue($valueName, $enabledValue, $disabledValue)

    # list value definitions
    if ( $PolicyElement.Item("enabledList") ) {
        Write-Verbose "Get enabledList information..."
        $defaultKey = ""
        if ( $PolicyElement.enabledList.HasAttribute("defaultKey") ) {
            $defaultKey = $PolicyElement.enabledList.defaultKey
        }
        $list = New-Object "AdmxPolicy.ValueDefinitionList" -ArgumentList $defaultKey
        foreach ( $i in $PolicyElement.enabledList.item ) {
            $args = @(
                $i.key,
                $i.valueName,
                (GetValueDefinitionFromXmlNode -ValueElement $i.value)
            )
            $list.Items.Add((New-Object "AdmxPolicy.ListItem" -ArgumentList $args))
        }
        $Result.set_EnabledListValue($list)
    }
    if ( $PolicyElement.Item("disabledList") ) {
        Write-Verbose "Get disabledList information..."
        $defaultKey = ""
        if ( $PolicyElement.disabledList.HasAttribute("defaultKey") ) {
            $defaultKey = $PolicyElement.disabledList.defaultKey
        }
        $list = New-Object "AdmxPolicy.ValueDefinitionList" -ArgumentList $defaultKey
        foreach ( $i in $PolicyElement.disabledList.item ) {
            $args = @(
                $i.key,
                $i.valueName,
                (GetValueDefinitionFromXmlNode -ValueElement $i.value)
            )
            $list.Items.Add((New-Object "AdmxPolicy.ListItem" -ArgumentList $args))
        }
        $Result.set_DisabledListValue($list)
    }

    # element value definition
    # ! Temporary implementation
    if ( $PolicyElement.Item("elements") ) {
        $Result._set_HasElement($true)
    }

    return $Result
}

<#
.SYNOPSIS
    Get group policy information from an ADMX file.
.DESCRIPTION
    This function reads an ADMX file and get group policy information.
.EXAMPLE
    Get-AdmxPolicies -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx"

    Set ADMX file path.
.EXAMPLE
    Get-AdmxPolicies -FilePath "C:\Windows\PolicyDefinitions\ActiveXInstallService.admx" -CultureName "ja-JP"

    Specify culture name.
#>
function Get-AdmxPolicies () {
    [OutputType([AdmxPolicy.PolicyInfo])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [string]$FilePath = "",
        [string]$CultureName = ((Get-Culture).Name)
    )
    begin {
        Write-Verbose "Start Get-AdmxPolicies..."
        Write-Verbose "CultureName : $CultureName"
        # set default
        if ( $CultureName -eq "" ) {
            $CultureName = (Get-Culture).Name
        }
    }
    process {
        # validation
        Write-Verbose "FilePath : $FilePath"
        if ( -not (Test-Path $FilePath -PathType Leaf) ) {
            throw [IO.FileNotFoundException] "Get-AdmxPolicies : $FilePath not found."
        }
        if ( [IO.Path]::GetExtension($FilePath) -ne ".admx" ) {
            throw [ArgumentException] "Get-AdmxPolicies : $FilePath must be .admx file."
        }

        # load xml
        try {
            $xml = [xml](Get-Content -LiteralPath $FilePath -Encoding UTF8)
        } catch {
            Write-Error $_
            return
        }

        # get adml resource
        $admlPath = Join-Path (Split-Path $FilePath -Parent) "$($CultureName)\$([IO.Path]::GetFileNameWithoutExtension($FilePath)).adml"
        $admlResource = New-Object "AdmxPolicy.AdmlResource"
        if ( -not (Test-Path -LiteralPath $admlPath) ) {
            Write-Warning "ADML file($admlPath) not found."
        } else {
            $admlResource = Get-AdmlResource -FilePath $admlPath -ForAdmxId:$true
        }

        # get policies
        $policies = $null
        try {
            $policies = $xml.policyDefinitions.policies.policy
        } catch {
            # WindowsProducts.admx などPolicy定義のないadmxファイルもある
        }
        foreach ( $policy in $policies ) {
            if ( $null -eq $policy ) {
                # for PowerShell 2.0
                continue
            }

            # get FileInfo
            # * create new FileInfo object for each PolicyInfo. 
            Write-Verbose "Get $($policy.name) FileInfo..."
            $fileInfo = GetAdmxFileInfoFromXml -Name ([IO.Path]::GetFileName($FilePath)) -Xml $xml -AdmlResource $admlResource
            
            Write-Verbose "Get $($policy.name) informations..."
            # get DisplayName
            $policyDisplayName = ""
            if ( $admlResource.Strings.ContainsKey($policy.displayName) ) {
                $policyDisplayName = $admlResource.Strings[$policy.displayName]
            }
            # get ExplainText
            $policyExplainText = ""
            if ( $admlResource.Strings.ContainsKey($policy.explainText) ) {
                $policyExplainText = $admlResource.Strings[$policy.explainText]
            }
            # get registry key
            $RegistryType = [AdmxPolicy.RegistryTypes]::Unknown
            switch ($policy.class) {
                "Machine" {
                    $RegistryType = [AdmxPolicy.RegistryTypes]::LocalMachine
                }
                "User" {
                    $RegistryType = [AdmxPolicy.RegistryTypes]::CurrentUser
                }
                "Both" {
                    $RegistryType = [AdmxPolicy.RegistryTypes]::Both
                }
            }
            $RegistryPath = $policy.key
            # get valueInfo
            $valueInfo = GetValueInfoFromXmlNode -PolicyElement $policy

            # set return value
            $Result = New-Object "AdmxPolicy.PolicyInfo" `
                -ArgumentList ($fileInfo, $policy.name, $policyDisplayName, $policyExplainText, $RegistryType, $RegistryPath, $valueInfo)
            Write-Output $Result
        }
    }
}
