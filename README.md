# win_wins - Manipulate the WINS settings specific to TCP/IP

## Synopsis

* This Ansible module allows to change the WINS settings specific to TCP/IP.

## Parameters

| Parameter     | Choices/<font color="blue">Defaults</font> | Comments |
| ------------- | ---------|--------- |
|__enable_dns__<br><font color="purple">boolean</font></font> | __Choices__: <ul><li>no</li><li>yes</li></ul> | Specifies whether the Domain Name System (DNS) is enabled for name resolution over WINS resolution.<br>If this value is set to `true`, NBT queries the DNS for names that cannot be resolved by WINS, broadcast, or the LMHOSTS file. |
|__enable_lmhosts_lookup__<br><font color="purple">boolean</font></font> | __Choices__: <ul><li>no</li><li>yes</li></ul> | Specifies whether local lookup files are used. Lookup files will contain mappings of IP addresses to host names.<br>If this value is set to `true`, NBT searches the LMHOSTS file, if it exists, for names that cannot be resolved by WINS or broadcast.<br>By default, there is no LMHOSTS file database directory. Therefore, NBT takes no action. |
|__scope_id__<br><font color="purple">string</font></font> |  | Specifies the Scope ID value that will be appended to the end of the computer’s NetBIOS name. Systems using the same Scope ID can communicate with this computer.<br>The value must not start with a period.<br>If this option contains a valid value, it will override the DHCP parameter of the same name.<br>A blank value (empty string) will be ignored.<br>The valid range is any valid DNS domain name consisting of two dot-separated parts, or a `*`.<br>Setting this option to the value `*` indicates a null scope and will override the DHCP parameter. |
|__adapter_names__<br><font color="purple">list</font></font> |  | Specifies the list of adapter names for which to set the primary or secondary Windows Internet Naming Service (WINS) servers.<br>Used only if _primary_server_ or _secondary_server_ are specified.<br>If this option is omitted then configuration is applied to all adapters on the system.<br>The adapter name used is the connection caption in the Network Control Panel or via `Get-NetAdapter`, eg `Ethernet 2`. |
|__primary_server__<br><font color="purple">string</font></font> |  | Specifies the dotted decimal IP address of the primary WINS server (for example,11.101.1.200).<br>If the _adapter_names_ option is omitted then configuration is applied to all adapters on the system.<br>If this option contains a valid value, it overrides the DHCP parameter of the same name. |
|__secondary_server__<br><font color="purple">string</font></font> |  | Specifies the dotted decimal IP address of the secondary WINS server (for example,11.101.1.200).<br>If the _adapter_names_ option is omitted then configuration is applied to all adapters on the system.<br>If this option contains a valid value, it overrides the DHCP parameter of the same name. |

## Examples

```yaml
---
- name: test the win_server_manager module
  hosts: all
  gather_facts: false

  roles:
    - win_wins

  tasks:
    - name: Disable DNS for name resolution over WINS for all adapters
      win_wins:
        enable_dns: false

    - name: Disable LMHOSTS lookup for all adapters
      win_wins:
        enable_lmhosts_lookup: false

    - name: Append test.local to the end of the computer's NetBIOS name for all adapters
      win_wins:
        scope_id: test.local

    - name: Set the IP address of the primary WINS server on Ethernet2
      win_wins:
        primary_server: 192.168.1.40
        adapter_names:
          - Ethernet2

    - name: Set the IP address of the primary WINS server on Public and Backup adapters
      win_wins:
        secondary_server: 192.168.1.50
        adapter_names:
          - Public
          - Backup

    - name: Set the WINS servers on all adapters
      win_wins:
        primary_server: 192.168.1.40
        secondary_server: 192.168.1.50

```

## Return Values

Common return values are documented [here](https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html#common-return-values), the following are the fields unique to this module:

| Key    | Returned   | Description |
| ------ |------------| ------------|
|__reboot_required__<br><font color="purple">boolean</font> | always | Boolean value stating whether a system reboot is required.<br><br>__Sample:__<br><font color=blue>True</font> |
|__config__<br><font color="purple">dictionary</font> | always | Detailed information about WINS. |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__enable_dns__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">boolean</font> | always | Indicates whether the Domain Name System (DNS) is enabled for name resolution over WINS resolution for all network adapters with TCP/IP enabled.<br><br>__Sample:__<br><font color=blue>True</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__enable_lmhosts_lookup__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">boolean</font> | always | Indicates whether LMHOSTS lookup should be enabled for all network adapters with TCP/IP enabled.<br><br>__Sample:__<br><font color=blue>True</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__scope_id__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">string</font> | always | The scope identifier value that will be appended to the end of the computer's NetBIOS name for all network adapters with TCP/IP enabled.<br><br>__Sample:__<br><font color=blue>test.local</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__adapters__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">dictionary</font> |  | Detailed information about WINS settings on network adapters. |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__name__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">dictionary</font> |  | The adapter name<br><br>__Sample:__<br><font color=blue>Ethernet2</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__interface_index__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">integer</font> |  | The Index value that uniquely identifies a local network interface.<br>The value of this property is the same as the value that represents the network interface in the route table.<br><br>__Sample:__<br><font color=blue>12</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__primary_server__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">string</font> |  | The IP address of the primary WINS server.<br><br>__Sample:__<br><font color=blue>192.168.1.40</font> |
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;__secondary_server__<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="purple">string</font> |  | The IP address of the secondary WINS server.<br><br>__Sample:__<br><font color=blue>192.168.1.50</font> |

## Notes

* Changing WINS settings does not usually require a reboot and will take effect immediately.

## Authors

* Stéphane Bilqué (@sbilque) Informatique CDC

## License

This project is licensed under the Apache 2.0 License.

See [LICENSE](LICENSE) to see the full text.
