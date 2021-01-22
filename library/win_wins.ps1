#!powershell

#AnsibleRequires -CSharpUtil Ansible.Basic

# Localized messages
data LocalizedData {
    # culture="en-US"
    ConvertFrom-StringData @'
    FailedUpdatingWinsSettingError = An error code of '{0}' was returned when attemting to update WINS settings.
    FailedUpdatingWINSServerError68 = Invalid input parameter when attemting to update WINS servers.
    FailedUpdatingWINSServerError75 = No primary/secondary WINS server defined.
'@
}

$spec = @{
    options             = @{
        enable_dns            = @{ type = "bool"; }
        enable_lmhosts_lookup = @{ type = "bool"; }
        scope_id              = @{ type = "str"; }
        adapter_names         = @{ type = "list"; elements = "str"; required = $false }
        primary_server        = @{ type = "str"; }
        secondary_server      = @{ type = "str"; }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$check_mode = $module.CheckMode
$diff_before = @{ }
$diff_after = @{ }

<#
    .SYNOPSIS
        Returns the current WINS settings.
    .OUTPUTS
        Returns a hashtable containing the values.
#>
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [string[]]$adapter_names
    )

    # 0 equals off, 1 equals on
    $enableLmHostsRegistryKey = Get-ItemProperty `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
        -Name EnableLMHOSTS `
        -ErrorAction SilentlyContinue

    $enableLmHosts = ($enableLmHostsRegistryKey.EnableLMHOSTS -eq 1)

    # 0 equals off, 1 equals on
    $enableDnsRegistryKey = Get-ItemProperty `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' `
        -Name EnableDNS `
        -ErrorAction SilentlyContinue

    if ($enableDnsRegistryKey) {
        $enableDns = ($enableDnsRegistryKey.EnableDNS -eq 1)
    }
    else {
        # if the key does not exist, then set the default which is enabled.
        $enableDns = $false
    }

    $wINSScopeIDRegistryKey = Get-ItemProperty `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Netbt\Parameters' `
        -Name ScopeID `
        -ErrorAction SilentlyContinue

    if ($wINSScopeIDRegistryKey) {
        $scopeID = $wINSScopeIDRegistryKey.scopeID
    }
    else {
        $scopeID = $null
    }

    if (-not $adapter_names) {
        # Target all network adapters on the system
        $get_params = @{
            ClassName = 'Win32_NetworkAdapterConfiguration'
            Filter    = 'IPEnabled=true'
            Property  = @('InterfaceIndex', 'WINSPrimaryServer', 'WINSSecondaryServer')
        }
        $target_adapters_config = Get-CimInstance @get_params
    }
    else {
        $get_params = @{
            Class   = 'Win32_NetworkAdapter'
            Filter  = ($adapter_names | ForEach-Object -Process { "NetConnectionId='$_'" }) -join " OR "
            KeyOnly = $true
        }
        $target_adapters_config = Get-CimInstance @get_params | Get-CimAssociatedInstance -ResultClassName 'Win32_NetworkAdapterConfiguration'
        if (($target_adapters_config | Measure-Object).Count -ne $adapter_names.Count) {
            $module.FailJson("Not all of the target adapter names could be found on the system. No configuration changes have been made. $adapter_names")
        }
    }

    $settings = @{
        enable_dns            = $enableDns
        enable_lmhosts_lookup = $enableLmHosts
        scope_id              = $scopeID
    }
    $settings.adapters = @{}

    foreach ($adapter in $target_adapters_config) {
        $name = (Get-CimInstance -Class Win32_NetworkAdapter -Property NetConnectionId -Filter "InterfaceIndex=$($adapter.InterfaceIndex)").NetConnectionId
        $WINSPrimaryServer = if ([string]::IsNullOrWhiteSpace($adapter.WINSPrimaryServer)) { "" } else { $adapter.WINSPrimaryServer }
        $WINSSecondaryServer = if ([string]::IsNullOrWhiteSpace($adapter.WINSSecondaryServer)) { "" } else { $adapter.WINSSecondaryServer }
        $settings.adapters.$name = @{
            interface_index  = $adapter.InterfaceIndex
            primary_server   = $WINSPrimaryServer
            secondary_server = $WINSSecondaryServer
        }
    }
    return $settings
}

<#
    .SYNOPSIS
        Sets the current configuration for the WINS setting.
    .PARAMETER enable_dns
        Specifies if the Domain Name System (DNS) is enabled for name resolution over WINS resolution for all network adapters with TCP/IP enabled.
    .PARAMETER enable_lmhosts_lookup
        Specifies if LMHOSTS lookup should be enabled for all network adapters with TCP/IP enabled.
    .PARAMETER scope_id
        Specifies the scope identifier value that will be appended to the end of the computer's NetBIOS name for all network adapters with TCP/IP enabled.
        Systems that use the same scope identifier can communicate with this computer.
    .PARAMETER adapter_names
        Specifies the list of adapter names for which to set the primary or secondary Windows Internet Naming Service (WINS) servers.
        If this option is omitted then configuration is applied to all adapters on the system.
        The adapter name used is the connection caption in the Network Control Panel or via Get-NetAdapter, eg Ethernet 2.
        Used only if primary_server or secondary_server are specified.
    .PARAMETER primary_server
        Specifies the IP address of the primary WINS server.
    .PARAMETER secondary_server
        Specifies the IP address of the secondary WINS server.
    #>
function Set-TargetResource {
    param
    (
        [Parameter()]
        [System.Boolean]
        $enable_dns,
        [Parameter()]
        [System.Boolean]
        $enable_lmhosts_lookup,
        [Parameter()]
        [System.String]
        $scope_id,
        [System.String[]]
        $adapter_names,
        [Parameter()]
        [System.String]
        $primary_server,
        [Parameter()]
        [System.String]
        $secondary_server
    )

    # Get the current values of the WINS settings
    $currentState = Get-TargetResource -adapter_names $adapter_names

    $module.Result.changed = $false

    $EnableDns = $currentState.enable_dns
    if ($PSBoundParameters.ContainsKey('enable_dns')) {
        if ($enable_dns -ne $currentState.enable_dns) {
            $EnableDns = $enable_dns
            $diff_before.enable_dns = $currentState.enable_dns
            $diff_after.enable_dns = $enable_dns
        }
    }

    $EnableLmHosts = $currentState.enable_lmhosts_lookup
    if ($PSBoundParameters.ContainsKey('enable_lmhosts_lookup')) {
        if ($enable_lmhosts_lookup -ne $currentState.enable_lmhosts_lookup) {
            $EnableLmHosts = $enable_lmhosts_lookup
            $diff_before.enable_lmhosts_lookup = $currentState.enable_lmhosts_lookup
            $diff_after.enable_lmhosts_lookup = $enable_lmhosts_lookup
        }
    }

    $ScopeID = $currentState.scope_id
    if ($PSBoundParameters.ContainsKey('scope_id')) {
        if ($scope_id -ne $currentState.scope_id) {
            $ScopeID = $scope_id
            $diff_before.scope_id = $currentState.scope_id
            $diff_after.scope_id = $scope_id
        }
    }

    if (-not $check_mode -and $diff_after.Keys.Count -gt 0) {

        $result = Invoke-CimMethod `
            -ClassName Win32_NetworkAdapterConfiguration `
            -MethodName EnableWins `
            -Arguments @{
            DNSEnabledForWINSResolution = $EnableDns
            WINSEnableLMHostsLookup     = $EnableLmHosts
            WINSScopeID                 = $ScopeID
        }
        switch ( $result.ReturnValue ) {
            0 { <# Success no reboot required #> }
            1 { $module.Result.reboot_required = $true }
            default { $module.FailJson(($script:localizedData.FailedUpdatingWinsSettingError -f $result.ReturnValue)) }
        }
    }

    $diff_after.adapters = @{}
    $diff_before.adapters = @{}

    foreach ($name in $currentState.adapters.Keys) {

        $WINSPrimaryServer = $currentState.adapters.$name.primary_server
        $WINSSecondaryServer = $currentState.adapters.$name.secondary_server

        if ($PSBoundParameters.ContainsKey('primary_server')) {
            if ($primary_server -ne $WINSPrimaryServer) {
                if (-not $diff_before.adapters.ContainsKey($name)) {
                    $diff_before.adapters.$name = @{}
                    $diff_after.adapters.$name = @{}
                }
                $diff_before.adapters.$name.primary_server = $WINSPrimaryServer
                $diff_after.adapters.$name.primary_server = $primary_server
                $WINSPrimaryServer = $primary_server
            }
        }
        if ($PSBoundParameters.ContainsKey('secondary_server')) {
            if ($secondary_server -ne $WINSSecondaryServer) {
                if (-not $diff_before.adapters.ContainsKey($name)) {
                    $diff_before.adapters.$name = @{}
                    $diff_after.adapters.$name = @{}
                }
                $diff_before.adapters.$name.secondary_server = $WINSSecondaryServer
                $diff_after.adapters.$name.secondary_server = $secondary_server
                $WINSSecondaryServer = $secondary_server
            }
        }

        if (-not $check_mode -and $diff_after.adapters.$name.Keys.Count -gt 0) {

            if ([string]::IsNullOrEmpty($WINSPrimaryServer) -and !([string]::IsNullOrEmpty($WINSSecondaryServer))) {
                $WINSPrimaryServer = $WINSSecondaryServer
                $WINSSecondaryServer = ""
                $diff_after.adapters.$name.primary_server = $WINSPrimaryServer
                $diff_after.adapters.$name.secondary_server = ""
            }

            $adapter = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "InterfaceIndex=$($currentState.adapters.$name.interface_index)"
            $result = $adapter | Invoke-CimMethod `
                -MethodName SetWINSServer `
                -Arguments @{
                WINSPrimaryServer   = $WINSPrimaryServer
                WINSSecondaryServer = $WINSSecondaryServer
            }

            switch ( $result.ReturnValue ) {
                0 { <# Success no reboot required #> }
                1 { $module.Result.reboot_required = $true }
                68 { $module.FailJson(($script:localizedData.FailedUpdatingWINSServerError68 -f $result.ReturnValue)) }
                75 { $module.FailJson(($script:localizedData.FailedUpdatingWINSServerError75 -f $result.ReturnValue)) }
                default { $module.FailJson(($script:localizedData.FailedUpdatingWINSServerError -f $result.ReturnValue)) }
            }
        }
    }

    if ($diff_after.adapters.Keys.Count -eq 0) {
        $diff_after.Remove('adapters')
        $diff_before.Remove('adapters')
    }

    if ($diff_after.Keys.Count -gt 0) {
        $module.Result.changed = $true
    }
}

$setTargetResourceParameters = @{}

foreach ($key in $module.Params.Keys) {
    if ($null -ne $module.Params[$key]) {
        $setTargetResourceParameters.$key = $module.Params[$key]
    }
}

Set-TargetResource @setTargetResourceParameters

$module.result.config = Get-TargetResource

if ($module.Result.changed) {
    $module.Diff.before = $diff_before
    $module.Diff.after = $diff_after
}

$module.ExitJson()
