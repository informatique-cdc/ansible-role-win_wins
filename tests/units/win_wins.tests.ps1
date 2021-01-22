# Set $ErrorActionPreference to what's set during Ansible execution
$ErrorActionPreference = "Stop"

#Get Current Directory
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

.$(Join-Path -Path $Here -ChildPath 'test_utils.ps1')

# Update Pester if needed
Update-Pester

#Get Function Name
$moduleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Tests.ps1"

#Resolve Path to Module path
$ansibleModulePath = "$Here\..\..\library\$moduleName.ps1"

Invoke-TestSetup

Function Invoke-AnsibleModule {
    [CmdletBinding()]
    Param(
        [hashtable]$params
    )

    begin {
        $global:complex_args = @{
            "_ansible_check_mode" = $false
            "_ansible_diff"       = $true
        } + $params
    }
    Process {
        . $ansibleModulePath
        return $module.result
    }
}

$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters'

try {

    Describe 'win_wins validation' {

        beforeAll {

            $global:EnableDns = 1
            $global:EnableLmhosts = 1
            $global:ScopeId = 'test.local'

            $NetworkAdapterConfiguration = @{
                Ethernet2 = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSPrimaryServer -Value '192.168.1.9' -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSSecondaryServer -Value '192.168.1.10' -PassThru
                )
                Public    = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSPrimaryServer -Value '192.168.1.9' -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSSecondaryServer -Value '192.168.1.10' -PassThru
                )
                Backup    = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapterConfiguration' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 3 -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSPrimaryServer -Value '192.168.1.9' -PassThru |
                    Add-Member -MemberType NoteProperty -Name WINSSecondaryServer -Value '192.168.1.10' -PassThru
                )
            }

            $NetworkAdapter = @{
                Ethernet2 = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapter' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 1 -PassThru |
                    Add-Member -MemberType NoteProperty -Name NetConnectionId -Value 'Ethernet2'-PassThru
                )
                Public    = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapter' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 2 -PassThru |
                    Add-Member -MemberType NoteProperty -Name NetConnectionId -Value 'Public'-PassThru
                )
                Backup    = (New-Object `
                        -TypeName CimInstance `
                        -ArgumentList 'Win32_NetworkAdapter' |
                    Add-Member -MemberType NoteProperty -Name InterfaceIndex -Value 3 -PassThru |
                    Add-Member -MemberType NoteProperty -Name NetConnectionId -Value 'Backup'-PassThru
                )
            }

            Mock Get-ItemProperty -ParameterFilter { $Name -eq 'EnableDns' -and $Path -eq $RegistryPath } -MockWith {
                return @{ EnableDns = $global:EnableDns }
            }

            Mock Get-ItemProperty -ParameterFilter { $Name -eq 'EnableLmhosts' -and $Path -eq $RegistryPath } -MockWith {
                return @{ EnableLmhosts = $global:EnableLmhosts }
            }

            Mock Get-ItemProperty -ParameterFilter { $Name -eq 'ScopeId' -and $Path -eq $RegistryPath } -MockWith {
                return @{ ScopeId = $global:ScopeId }
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq 'IPEnabled=true' } -MockWith {
                $NetworkAdapterConfiguration.Ethernet2
            }

            Mock Get-CimAssociatedInstance -ParameterFilter { $ResultClass -eq 'Win32_NetworkAdapterConfiguration' } -MockWith {
                $NetworkAdapterConfiguration.Ethernet2
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "NetConnectionId='Ethernet2'" } -MockWith {
                $NetworkAdapter.Ethernet2
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "NetConnectionId='Public'" } -MockWith {
                $NetworkAdapter.Public
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "NetConnectionId='Backup'" } -MockWith {
                $NetworkAdapter.Backup
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "InterfaceIndex=1" } -MockWith {
                $NetworkAdapter.Ethernet2
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "InterfaceIndex=2" } -MockWith {
                $NetworkAdapter.Public
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -eq "InterfaceIndex=3" } -MockWith {
                $NetworkAdapter.Backup
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq "InterfaceIndex=1" } -MockWith {
                $NetworkAdapterConfiguration.Ethernet2
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq "InterfaceIndex=2" } -MockWith {
                $NetworkAdapterConfiguration.Public
            }

            Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq "InterfaceIndex=3" } -MockWith {
                $NetworkAdapterConfiguration.Backup
            }
        }

        Context "Return the configuration only" {

            It 'Setting should return no changed' {

                $params = @{}
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeFalse
                $result.config.enable_dns | Should -Be $true
                $result.config.enable_lmhosts_lookup | Should -Be $true
                $result.config.scope_id | Should -Be $global:ScopeId
                $result.config.adapters.Ethernet2.primary_server  | Should -Be $NetworkAdapterConfiguration.Ethernet2.WINSPrimaryServer
                $result.config.adapters.Ethernet2.secondary_server  | Should -Be $NetworkAdapterConfiguration.Ethernet2.WINSSecondaryServer
            }
        }

        Context 'Use the Domain Name System (DNS) for name resolution over WINS resolution is set to "Disable"' {

            Mock Invoke-CimMethod -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $MethodName -eq 'EnableWins' } -MockWith {
                @{ ReturnValue = 0 }
            }

            It 'Setting should return changed' {
                $params = @{
                    enable_dns = $false
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
            }
        }

        Context 'Use local lookup files is set to "Disable"' {

            Mock Invoke-CimMethod -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $MethodName -eq 'EnableWins' } -MockWith {
                @{ ReturnValue = 0 }
            }

            It 'Setting should return changed' {
                $params = @{
                    enable_lmhosts_lookup = $false
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
            }
        }

        Context 'Use of the Scope identifier is set' {

            Mock Invoke-CimMethod -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $MethodName -eq 'EnableWins' } -MockWith {
                @{ ReturnValue = 0 }
            }

            It 'Setting should return changed' {

                $params = @{
                    scope_id = ''
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
            }
        }

        context 'Update the IP address of the primary WINS server on Ethernet2' {

            It 'Setting should return changed' {

                Mock Get-CimAssociatedInstance -MockWith { $NetworkAdapterConfiguration.Ethernet2 }

                Mock -CommandName Invoke-CimMethod -MockWith {
                    $NetworkAdapterConfiguration.Ethernet2.WINSPrimaryServer = '192.168.1.14'
                    @{ ReturnValue = 0 }
                }

                $params = @{
                    adapter_names  = @('Ethernet2')
                    primary_server = '192.168.1.14'
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.config.adapters.Ethernet2.primary_server | Should -Be $params.primary_server
            }
        }

        context 'Update the IP address of the primary WINS server on Public and Backup adapters' {

            It 'Setting should return changed' {

                $global:GetCimAssociatedInstanceCount = 0
                Mock Get-CimAssociatedInstance -ParameterFilter { $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' } -MockWith {
                    if ($global:GetCimAssociatedInstanceCount -eq 0 ) {
                        $global:GetCimAssociatedInstanceCount = $global:GetCimAssociatedInstanceCount + 1
                        @($NetworkAdapterConfiguration.Public, $NetworkAdapterConfiguration.Backup)
                    }
                }

                Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq 'IPEnabled=true' } -MockWith {
                    @($NetworkAdapterConfiguration.Ethernet2, $NetworkAdapterConfiguration.Public, $NetworkAdapterConfiguration.Backup)
                }

                Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -match "NetConnectionId*" -and $KeyOnly -eq $true } -MockWith {
                    @($NetworkAdapter.Public, $NetworkAdapter.Backup)
                }

                Mock -CommandName Invoke-CimMethod -MockWith {
                    $NetworkAdapterConfiguration.Public.WINSPrimaryServer = '192.168.1.16'
                    $NetworkAdapterConfiguration.Backup.WINSPrimaryServer = '192.168.1.16'
                    @{ ReturnValue = 0 }
                }

                $params = @{
                    adapter_names  = @('Public', 'Backup')
                    primary_server = '192.168.1.16'
                }
                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.config.adapters.Public.primary_server | Should -Be $params.primary_server
                $result.config.adapters.Backup.primary_server | Should -Be $params.primary_server
            }
        }

        context 'Update the WINS servers on all adapters' {

            It 'Setting should return changed' {

                $WINSPrimaryServer = '192.168.1.17'
                $WINSSecondaryServer = '192.168.1.18'

                $global:GetCimAssociatedInstanceCount = 0
                Mock Get-CimAssociatedInstance  -ParameterFilter { $ResultClassName -eq 'Win32_NetworkAdapterConfiguration' } -MockWith {
                    if ($global:GetCimAssociatedInstanceCount -eq 0 ) {
                        $global:GetCimAssociatedInstanceCount = $global:GetCimAssociatedInstanceCount + 1
                        @($NetworkAdapterConfiguration.Ethernet2, $NetworkAdapterConfiguration.Public, $NetworkAdapterConfiguration.Backup)
                    }
                }

                Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq 'IPEnabled=true' } -MockWith {
                    @($NetworkAdapterConfiguration.Ethernet2, $NetworkAdapterConfiguration.Public, $NetworkAdapterConfiguration.Backup)
                }

                Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_NetworkAdapter' -and $Filter -match "NetConnectionId=*" -and $KeyOnly -eq $true } -MockWith {
                    @($NetworkAdapter.Ethernet2, $NetworkAdapter.Public, $NetworkAdapter.Backup)
                }

                Mock -CommandName Invoke-CimMethod -MockWith {
                    $NetworkAdapterConfiguration.Ethernet2.WINSPrimaryServer = $WINSPrimaryServer
                    $NetworkAdapterConfiguration.Public.WINSPrimaryServer = $WINSPrimaryServer
                    $NetworkAdapterConfiguration.Backup.WINSPrimaryServer = $WINSPrimaryServer

                    $NetworkAdapterConfiguration.Ethernet2.WINSSecondaryServer = $WINSSecondaryServer
                    $NetworkAdapterConfiguration.Public.WINSSecondaryServer = $WINSSecondaryServer
                    $NetworkAdapterConfiguration.Backup.WINSSecondaryServer = $WINSSecondaryServer
                    @{ ReturnValue = 0 }
                }

                $params = @{
                    primary_server   = $WINSPrimaryServer
                    secondary_server = $WINSSecondaryServer
                }

                $result = Invoke-AnsibleModule -params $params
                $result.changed | Should -BeTrue
                $result.config.adapters.Ethernet2.primary_server | Should -Be $params.primary_server
                $result.config.adapters.Public.primary_server | Should -Be $params.primary_server
                $result.config.adapters.Backup.primary_server | Should -Be $params.primary_server
                $result.config.adapters.Ethernet2.secondary_server | Should -Be $params.secondary_server
                $result.config.adapters.Public.secondary_server | Should -Be $params.secondary_server
                $result.config.adapters.Backup.secondary_server | Should -Be $params.secondary_server
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}