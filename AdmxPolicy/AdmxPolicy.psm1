#requires -Version 2.0
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
function TryGetAttribute ([Xml.XmlElement]$Element, [string]$AttributeName, [object]$Default) {
    if ( $Element.HasAttribute($AttributeName) ) {
        return $Element.$AttributeName
    }
    return $Default
}

# Private
function GetElementsInfoFromXmlNode ([Xml.XmlElement]$Elements, [AdmxPolicy.AdmlResource]$AdmlResource) {
    $Result = New-Object "AdmxPolicy.ValueDefinitionElements"
    foreach ( $element in $Elements.ChildNodes ) {
        if ( $element.NodeType -ne "Element" ) {
            # skip comment, text etc.
            continue
        }
        $item = $null
        $id = $element.id
        $registryPath = TryGetAttribute $element "key" ""
        $registryValueName = TryGetAttribute $element "valueName" ""
        switch ( $element.name ) {
            "boolean" { 
                $item = New-Object "AdmxPolicy.BooleanDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $trueValue = $null
                if ( $element.Item("trueValue") ) {
                    $trueValue = GetValueDefinitionFromXmlNode -ValueElement $element.trueValue
                }
                $falseValue = $null
                if ( $element.Item("falseValue") ) {
                    $falseValue = GetValueDefinitionFromXmlNode -ValueElement $element.falseValue
                }
                # TODO : implement trueList, falseList.(No admx files has theres elements?)
                $item.set_Properties($trueValue, $falseValue)
            }
            "decimal" { 
                $item = New-Object "AdmxPolicy.DecimalDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $required = TryGetAttribute $element "required" $false
                $minValue = TryGetAttribute $element "minValue" 0
                $maxValue = TryGetAttribute $element "maxValue" 9999
                $storeAsText = TryGetAttribute $element "storeAsText" $false
                $soft = TryGetAttribute $element "soft" $false
                $item.set_Properties($required, $minValue, $maxValue, $storeAsText, $soft)
            }
            "longdecimal" { 
                $item = New-Object "AdmxPolicy.LongDecimalDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $required = TryGetAttribute $element "required" $false
                $minValue = TryGetAttribute $element "minValue" 0
                $maxValue = TryGetAttribute $element "maxValue" 9999
                $storeAsText = TryGetAttribute $element "storeAsText" $false
                $soft = TryGetAttribute $element "soft" $false
                $item.set_Properties($required, $minValue, $maxValue, $storeAsText, $soft)
            }
            "text" { 
                $item = New-Object "AdmxPolicy.TextDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $required = TryGetAttribute $element "required" $false
                $maxLength = TryGetAttribute $element "maxLength" 1023
                $soft = TryGetAttribute $element "soft" $false
                $expandable = TryGetAttribute $element "expandable" $false
                $item.set_Properties($required, $maxLength, $soft, $expandable)
            }
            "multitext" {
                $item = New-Object "AdmxPolicy.MultiTextDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $required = TryGetAttribute $element "required" $false
                $maxLength = TryGetAttribute $element "maxLength" 1023
                $maxStrings = TryGetAttribute $element "maxStrings" 0
                $soft = TryGetAttribute $element "soft" $false
                $item.set_Properties($required, $maxLength, $maxStrings, $soft)
            }
            "enum" { 
                $item = New-Object "AdmxPolicy.EnumDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $required = TryGetAttribute $element "required" $false
                $item.set_Properties($required)
                # TODO : implement when item cotains valueList.(e.g. Bits.admx)
                foreach ($i in $element.item) {
                    $enumKey = $i.displayName
                    if ( $admlResource.Strings.ContainsKey($enumKey) ) {
                        $enumKey = $admlResource.Strings[$enumKey]
                    }
                    $enumValue = GetValueDefinitionFromXmlNode -ValueElement $i.value
                    $item.add_EnumsItem($enumKey, $enumValue)
                }
            }
            "list" { 
                $item = New-Object "AdmxPolicy.ListDefinitionElement" -ArgumentList ($id, $registryPath, $registryValueName)
                $prefix = TryGetAttribute $element "valuePrefix" ""
                $additive = TryGetAttribute $element "additive" $false
                $expandable = TryGetAttribute $element "expandable" $false
                $explicitValue = TryGetAttribute $element "explicitValue" $false
                $clientExtension = TryGetAttribute $element "clientExtension" ""
                $item.set_Properties($prefix, $additive, $expandable, $explicitValue, $clientExtension)
            }
            Default {
                # unknown type. do nothing.
            }
        }
        if ( $null -ne $item ) {
            $Result.Items.Add($item)
        }
    }
    return $Result
}

# Private 
function GetValueInfoFromXmlNode ([Xml.XmlElement]$PolicyElement, [AdmxPolicy.AdmlResource]$AdmlResource) {
    $Result = New-Object "AdmxPolicy.PolicyValueInfo"

    # base value definitions
    $valueName = TryGetAttribute $PolicyElement "valueName" ""
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
        $defaultKey = TryGetAttribute $PolicyElement.enabledList "defaultKey" ""
        $list = New-Object "AdmxPolicy.ValueDefinitionList" -ArgumentList $defaultKey
        foreach ( $i in $PolicyElement.enabledList.item ) {
            $list.Items.Add((New-Object "AdmxPolicy.ListItem" `
                    -ArgumentList ($i.key, $i.valueName, (GetValueDefinitionFromXmlNode -ValueElement $i.value))))
        }
        $Result.set_EnabledListValue($list)
    }
    if ( $PolicyElement.Item("disabledList") ) {
        Write-Verbose "Get disabledList information..."
        $defaultKey = TryGetAttribute $PolicyElement.disabledList "defaultKey" ""
        $list = New-Object "AdmxPolicy.ValueDefinitionList" -ArgumentList $defaultKey
        foreach ( $i in $PolicyElement.disabledList.item ) {
            $list.Items.Add((New-Object "AdmxPolicy.ListItem" `
                                -ArgumentList ($i.key, $i.valueName, (GetValueDefinitionFromXmlNode -ValueElement $i.value))))
        }
        $Result.set_DisabledListValue($list)
    }

    # element value definition
    if ( $PolicyElement.Item("elements") ) {
        $Result.set_ElementsValue((GetElementsInfoFromXmlNode -Elements $PolicyElement.elements -AdmlResource $AdmlResource))
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
            $valueInfo = GetValueInfoFromXmlNode -PolicyElement $policy -AdmlResource $admlResource

            # set return value
            $Result = New-Object "AdmxPolicy.PolicyInfo" `
                -ArgumentList ($fileInfo, $policy.name, $policyDisplayName, $policyExplainText, $RegistryType, $RegistryPath, $valueInfo)
            Write-Output $Result
        }
    }
}
