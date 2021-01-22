#!/usr/bin/python
# -*- coding: utf-8 -*-

# This is a role documentation stub.

# Copyright 2020 Informatique CDC. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_wins
short_description: Manipulate the WINS settings specific to TCP/IP
author:
    - Stéphane Bilqué (@sbilque) Informatique CDC
notes:
    - Changing WINS settings does not usually require a reboot and will take effect immediately.
description:
    - This Ansible module allows to change the WINS settings specific to TCP/IP.
options:
    enable_dns:
        description:
            - Specifies whether the Domain Name System (DNS) is enabled for name resolution over WINS resolution.
            - If this value is set to C(true), NBT queries the DNS for names that cannot be resolved by WINS, broadcast, or the LMHOSTS file.
        type: bool
        choices: [ true, false ]
    enable_lmhosts_lookup:
        description:
            - Specifies whether local lookup files are used. Lookup files will contain mappings of IP addresses to host names.
            - If this value is set to C(true), NBT searches the LMHOSTS file, if it exists, for names that cannot be resolved by WINS or broadcast.
            - By default, there is no LMHOSTS file database directory. Therefore, NBT takes no action.
        type: bool
        choices: [ true, false ]
    scope_id:
        description:
            - Specifies the Scope ID value that will be appended to the end of the computer’s NetBIOS name. Systems using the same Scope ID can communicate with this computer.
            - The value must not start with a period.
            - If this option contains a valid value, it will override the DHCP parameter of the same name.
            - A blank value (empty string) will be ignored.
            - The valid range is any valid DNS domain name consisting of two dot-separated parts, or a C(*).
            - Setting this option to the value C(*) indicates a null scope and will override the DHCP parameter.
        type: str
    adapter_names:
        description:
            - Specifies the list of adapter names for which to set the primary or secondary Windows Internet Naming Service (WINS) servers.
            - Used only if I(primary_server) or I(secondary_server) are specified.
            - If this option is omitted then configuration is applied to all adapters on the system.
            - The adapter name used is the connection caption in the Network Control Panel or via C(Get-NetAdapter), eg C(Ethernet 2).
        type: list
        elements: str
        required: no
    primary_server:
        description:
            - Specifies the dotted decimal IP address of the primary WINS server (for example,11.101.1.200).
            - If the I(adapter_names) option is omitted then configuration is applied to all adapters on the system.
            - If this option contains a valid value, it overrides the DHCP parameter of the same name.
        type: str
    secondary_server:
        description:
            - Specifies the dotted decimal IP address of the secondary WINS server (for example,11.101.1.200).
            - If the I(adapter_names) option is omitted then configuration is applied to all adapters on the system.
            - If this option contains a valid value, it overrides the DHCP parameter of the same name.
        type: str
'''

EXAMPLES = r'''
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
'''

RETURN = r'''
reboot_required:
    description: Boolean value stating whether a system reboot is required.
    returned: always
    type: bool
    sample: true
config:
    description: Detailed information about WINS.
    returned: always
    type: dict
    contains:
        enable_dns:
            description:
                - Indicates whether the Domain Name System (DNS) is enabled for name resolution over WINS resolution for all network adapters with TCP/IP enabled.
            type: bool
            returned: always
            sample: true
        enable_lmhosts_lookup:
            description:
                - Indicates whether LMHOSTS lookup should be enabled for all network adapters with TCP/IP enabled.
            type: bool
            returned: always
            sample: true
        scope_id:
            description:
                - The scope identifier value that will be appended to the end of the computer's NetBIOS name for all network adapters with TCP/IP enabled.
            type: str
            returned: always
            sample: test.local
        adapters:
            description: Detailed information about WINS settings on network adapters.
            type: dict
            contains:
                name:
                    description: The adapter name
                    type: dict
                    sample: Ethernet2
                    contains:
                        interface_index:
                            description:
                                - The Index value that uniquely identifies a local network interface.
                                - The value of this property is the same as the value that represents the network interface in the route table.
                            type: int
                            sample: 12
                        primary_server:
                            description: The IP address of the primary WINS server.
                            type: str
                            sample: 192.168.1.40
                        secondary_server:
                            description: The IP address of the secondary WINS server.
                            type: str
                            sample: 192.168.1.50
'''
