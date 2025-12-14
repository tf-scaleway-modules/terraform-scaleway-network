# Scaleway Network Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A Terraform module for creating and managing **Scaleway** Network infrastructure. This module provisions VPCs, private networks, public gateways with NAT, Access Control Lists for traffic filtering, and optional SSH bastion hosts. It supports multi-zone deployments for high availability and provides flexible network configuration with IPv4/IPv6 support.

## Usage Examples

A comprehensive examples available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.64 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_ipam_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/ipam_ip) | resource |
| [scaleway_vpc.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc) | resource |
| [scaleway_vpc_acl.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_acl) | resource |
| [scaleway_vpc_gateway_network.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_gateway_network) | resource |
| [scaleway_vpc_private_network.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_private_network) | resource |
| [scaleway_vpc_public_gateway.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_public_gateway) | resource |
| [scaleway_vpc_public_gateway_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_public_gateway_ip) | resource |
| [scaleway_account_project.project](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_control_list_default_policy"></a> [access\_control\_list\_default\_policy](#input\_access\_control\_list\_default\_policy) | Default action when no ACL rules match: accept or drop | `string` | `"accept"` | no |
| <a name="input_access_control_list_is_ipv6"></a> [access\_control\_list\_is\_ipv6](#input\_access\_control\_list\_is\_ipv6) | Apply ACL rules to IPv6 traffic instead of IPv4 | `bool` | `false` | no |
| <a name="input_access_control_list_rules"></a> [access\_control\_list\_rules](#input\_access\_control\_list\_rules) | ACL rules for traffic filtering (protocol, ports, source/destination, action) | <pre>list(object({<br/>    protocol      = string # Protocol: ANY, TCP, UDP, or ICMP<br/>    src_port_low  = number<br/>    src_port_high = number<br/>    dst_port_low  = number<br/>    dst_port_high = number<br/>    source        = string<br/>    destination   = string<br/>    description   = string<br/>    action        = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "action": "accept",<br/>    "description": "Allow HTTP traffic from any source",<br/>    "destination": "0.0.0.0/0",<br/>    "dst_port_high": 80,<br/>    "dst_port_low": 80,<br/>    "protocol": "TCP",<br/>    "source": "0.0.0.0/0",<br/>    "src_port_high": 0,<br/>    "src_port_low": 0<br/>  }<br/>]</pre> | no |
| <a name="input_bastion_allowed_ip_ranges"></a> [bastion\_allowed\_ip\_ranges](#input\_bastion\_allowed\_ip\_ranges) | CIDR ranges allowed to access SSH bastion | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_bastion_ssh_port"></a> [bastion\_ssh\_port](#input\_bastion\_ssh\_port) | SSH port for bastion access (1-65535) | `number` | `61000` | no |
| <a name="input_enable_access_control_list"></a> [enable\_access\_control\_list](#input\_enable\_access\_control\_list) | Create VPC Access Control List for traffic filtering | `bool` | `false` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | Enable SSH bastion on public gateways for secure access | `bool` | `false` | no |
| <a name="input_enable_gateway"></a> [enable\_gateway](#input\_enable\_gateway) | Create public gateways for internet connectivity | `bool` | `true` | no |
| <a name="input_gateway_enable_masquerade"></a> [gateway\_enable\_masquerade](#input\_gateway\_enable\_masquerade) | Enable NAT masquerade for outbound internet access | `bool` | `true` | no |
| <a name="input_gateway_enable_smtp"></a> [gateway\_enable\_smtp](#input\_gateway\_enable\_smtp) | Enable SMTP (port 25) for email delivery | `bool` | `false` | no |
| <a name="input_gateway_existing_flexible_ip_id"></a> [gateway\_existing\_flexible\_ip\_id](#input\_gateway\_existing\_flexible\_ip\_id) | Existing flexible IP ID to attach (overrides gateway\_reserve\_flexible\_ip) | `string` | `null` | no |
| <a name="input_gateway_refresh_ssh_keys"></a> [gateway\_refresh\_ssh\_keys](#input\_gateway\_refresh\_ssh\_keys) | Trigger SSH key refresh on gateways (change value to trigger) | `string` | `null` | no |
| <a name="input_gateway_reserve_flexible_ip"></a> [gateway\_reserve\_flexible\_ip](#input\_gateway\_reserve\_flexible\_ip) | Reserve new flexible IP addresses for gateways | `bool` | `true` | no |
| <a name="input_gateway_type"></a> [gateway\_type](#input\_gateway\_type) | Gateway instance type: VPC-GW-S (small) or VPC-GW-M (medium) | `string` | `"VPC-GW-S"` | no |
| <a name="input_network_private_networks"></a> [network\_private\_networks](#input\_network\_private\_networks) | Private networks to create with optional names, subnets, and tags | <pre>map(object({<br/>    name        = optional(string)           # Network name (defaults to auto-generated)<br/>    ipv4_subnet = optional(string)           # IPv4 CIDR (defaults to auto-assigned /22)<br/>    ipv6_subnet = optional(string)           # IPv6 CIDR (defaults to auto-assigned /64)<br/>    tags        = optional(list(string), []) # Network-specific tags<br/>  }))</pre> | <pre>{<br/>  "default": {<br/>    "ipv4_subnet": null,<br/>    "ipv6_subnet": null,<br/>    "name": null,<br/>    "tags": []<br/>  }<br/>}</pre> | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Organization ID for VPC resources | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for VPC resources | `string` | n/a | yes |
| <a name="input_vpc_enable_custom_routes"></a> [vpc\_enable\_custom\_routes](#input\_vpc\_enable\_custom\_routes) | Enable custom route propagation between private networks | `bool` | `true` | no |
| <a name="input_vpc_enable_routing"></a> [vpc\_enable\_routing](#input\_vpc\_enable\_routing) | Enable routing between private networks (cannot be disabled once enabled) | `bool` | `true` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name prefix for the VPC and associated resources | `string` | n/a | yes |
| <a name="input_vpc_region"></a> [vpc\_region](#input\_vpc\_region) | Region where VPC resources will be created (defaults to provider configuration) | `string` | `null` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Tags to apply to all VPC resources | `list(string)` | `[]` | no |
| <a name="input_vpc_zones"></a> [vpc\_zones](#input\_vpc\_zones) | Availability zones for gateway deployment (must belong to vpc\_region if both specified) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_control_list_id"></a> [access\_control\_list\_id](#output\_access\_control\_list\_id) | VPC Access Control List ID (null if ACL not created) |
| <a name="output_gateway_flexible_ip_addresses"></a> [gateway\_flexible\_ip\_addresses](#output\_gateway\_flexible\_ip\_addresses) | Gateway public IP addresses by zone |
| <a name="output_gateway_flexible_ip_ids"></a> [gateway\_flexible\_ip\_ids](#output\_gateway\_flexible\_ip\_ids) | Gateway flexible IP resource IDs by zone |
| <a name="output_gateway_ids"></a> [gateway\_ids](#output\_gateway\_ids) | Public gateway IDs by zone |
| <a name="output_gateway_network_ids"></a> [gateway\_network\_ids](#output\_gateway\_network\_ids) | Gateway network attachment IDs by network-zone pair (e.g., web-fr-par-1) |
| <a name="output_ipam_ip_addresses"></a> [ipam\_ip\_addresses](#output\_ipam\_ip\_addresses) | IPAM IP addresses by network-zone pair |
| <a name="output_ipam_ip_ids"></a> [ipam\_ip\_ids](#output\_ipam\_ip\_ids) | IPAM IP resource IDs by network-zone pair |
| <a name="output_network_ipv4_cidrs"></a> [network\_ipv4\_cidrs](#output\_network\_ipv4\_cidrs) | IPv4 CIDR blocks by network name |
| <a name="output_network_ipv6_cidrs"></a> [network\_ipv6\_cidrs](#output\_network\_ipv6\_cidrs) | IPv6 CIDR blocks by network name |
| <a name="output_network_private_network_ids"></a> [network\_private\_network\_ids](#output\_network\_private\_network\_ids) | Private network IDs by network name |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC resource identifier |
<!-- END_TF_DOCS -->

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.63-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-vpc?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-vpc/-/releases
