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

## Upgrading from v1 to v2

v2.0.0 requires the Scaleway provider `~> 2.89` and replaces the 24 flat inputs by 10 (`project_id`, `region`, `zones`, `name`, `tags`, `enable_transitivity`, `private_networks`, `gateway`, `access_control_list`, `routes`); only `name` is required. No resource is replaced for an unchanged setup. The plan shows only the in-place renames below and the ACL `moved`.

### Inputs

| v1 | v2 |
|----|----|
| `organization_id`, `project_name` | removed; pass the project UUID as `project_id` (omit it for the provider's default project) |
| `vpc_name` | `name` (gateways are now named `<name>-<zone>`) |
| `vpc_region`, `vpc_zones` | `region`, `zones` |
| `vpc_tags` | `tags` (also applied to routes; per-network tags are merged without duplicates) |
| `vpc_enable_transitivity` | `enable_transitivity` |
| `vpc_enable_routing`, `vpc_enable_custom_routes` | removed; the provider always enables both, delete them |
| `network_private_networks` | `private_networks` (same shape) |
| `enable_gateway = false` | `gateway = null` |
| `gateway_type`, `gateway_enable_masquerade`, `gateway_enable_smtp`, `gateway_refresh_ssh_keys` | `gateway.type` (now also `VPC-GW-L`, `VPC-GW-XL`), `gateway.enable_masquerade`, `gateway.enable_smtp`, `gateway.refresh_ssh_keys` |
| `gateway_reserve_flexible_ip = false` + `gateway_existing_flexible_ip_id = X` | `gateway = { flexible_ip_ids = { "<zone>" = X } }`; zones not listed get a reserved IP |
| `enable_bastion = true`, `bastion_ssh_port`, `bastion_allowed_ip_ranges` | `gateway.bastion = { port, allowed_ip_ranges }`; `bastion = null` (default) replaces `enable_bastion = false` |
| `enable_access_control_list`, `access_control_list_is_ipv6`, `access_control_list_default_policy`, `access_control_list_rules` | `access_control_list = { ipv4 = { default_policy, rules }, ipv6 = { ... } }`; `null` (default) replaces `enable_access_control_list = false` |

### Outputs

| v1 | v2 |
|----|----|
| `network_private_network_ids` | `private_network_ids` |
| `network_ipv4_cidrs` | `private_network_ipv4_cidrs` |
| `network_ipv6_cidrs` | `private_network_ipv6_cidrs` |
| `access_control_list_id` | `access_control_list_ids`, a map by family: read `["ipv4"]` for the former value |

New: `route_ids`, `pat_rule_ids`. New inputs: `routes` (custom VPC routes) and `gateway.pat_rules` (port forwarding).

### Behaviour changes

- **Gateway names** change from `<name>` to `<name>-<zone>`: an in-place update. The name is derived from `name`, so accept the rename.
- **Unnamed private networks** (no `name`) are renamed from the provider-generated name to `<name>-<key>`: an in-place update. Set `name` on the network to keep the old name.
- **Bastion**: `allowed_ip_ranges` has no `0.0.0.0/0` default any more and is required whenever `gateway.bastion` is set. List the CIDRs that may reach the bastion.
- **ACL**: the default HTTP rule is gone (`rules` defaults to `[]`) and rule ports default to `0` (any port). Add the rule explicitly if you relied on it. `default_policy` still defaults to `accept`.
- **Bastion off**: the module no longer sends `bastion_port` and `allowed_ip_ranges` when the bastion is disabled. If the first plan shows a diff on these two arguments, apply it: the bastion stays disabled.

### Access control list state

The module moves `scaleway_vpc_acl.this[0]` to `scaleway_vpc_acl.this["ipv4"]` with a `moved` block, so IPv4 ACLs need nothing more. A `moved` block cannot know that the former ACL was IPv6 (`access_control_list_is_ipv6 = true`). If your ACL was IPv6, do one of the following before the first apply; otherwise the plan destroys `this["ipv4"]` and creates `this["ipv6"]`, a replacement that leaves the IPv6 filtering unset in between:

1. Add a `moved` block to the root module that calls this module (it chains after the module's own `moved`; replace `network` with your module name), then plan and apply:

   ```hcl
   moved {
     from = module.network.scaleway_vpc_acl.this["ipv4"]
     to   = module.network.scaleway_vpc_acl.this["ipv6"]
   }
   ```

   Remove it once applied.

2. Or run once, before the upgrade apply: `tofu state mv 'module.network.scaleway_vpc_acl.this[0]' 'module.network.scaleway_vpc_acl.this["ipv6"]'`.

Configure the family you used: `access_control_list = { ipv6 = { ... } }`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

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
| [scaleway_vpc_public_gateway_pat_rule.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_public_gateway_pat_rule) | resource |
| [scaleway_vpc_route.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/vpc_route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_control_list"></a> [access\_control\_list](#input\_access\_control\_list) | VPC access control list, one ACL per IP family set (null disables it); each family has a default\_policy (accept or drop) and ordered rules (protocol: ANY, TCP, UDP or ICMP; action: accept or drop; ports 0-65535, 0 meaning any); CIDRs are given in network address form | <pre>object({<br/>    ipv4 = optional(object({<br/>      default_policy = optional(string, "accept")<br/>      rules = optional(list(object({<br/>        source        = string<br/>        destination   = string<br/>        action        = string<br/>        protocol      = optional(string, "ANY")<br/>        src_port_low  = optional(number, 0)<br/>        src_port_high = optional(number, 0)<br/>        dst_port_low  = optional(number, 0)<br/>        dst_port_high = optional(number, 0)<br/>        description   = optional(string)<br/>      })), [])<br/>    }))<br/>    ipv6 = optional(object({<br/>      default_policy = optional(string, "accept")<br/>      rules = optional(list(object({<br/>        source        = string<br/>        destination   = string<br/>        action        = string<br/>        protocol      = optional(string, "ANY")<br/>        src_port_low  = optional(number, 0)<br/>        src_port_high = optional(number, 0)<br/>        dst_port_low  = optional(number, 0)<br/>        dst_port_high = optional(number, 0)<br/>        description   = optional(string)<br/>      })), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_enable_transitivity"></a> [enable\_transitivity](#input\_enable\_transitivity) | Allow packets from peered VPCs (VPC connectors) to transit through this VPC | `bool` | `false` | no |
| <a name="input_gateway"></a> [gateway](#input\_gateway) | Public gateway settings, one gateway per zone of zones (null disables the gateways). type: VPC-GW-S/M/L/XL; flexible\_ip\_ids: zone to existing flexible IP ID (other zones get a reserved IP); refresh\_ssh\_keys: change the value to refresh SSH keys; bastion: SSH bastion (allowed\_ip\_ranges required); pat\_rules: port forwarding rules keyed by name | <pre>object({<br/>    type              = optional(string, "VPC-GW-S")<br/>    flexible_ip_ids   = optional(map(string), {})<br/>    enable_masquerade = optional(bool, true)<br/>    enable_smtp       = optional(bool, false)<br/>    refresh_ssh_keys  = optional(string)<br/>    bastion = optional(object({<br/>      port              = optional(number, 61000)<br/>      allowed_ip_ranges = list(string)<br/>    }))<br/>    pat_rules = optional(map(object({<br/>      zone         = string<br/>      public_port  = number<br/>      private_ip   = string<br/>      private_port = number<br/>      protocol     = optional(string, "both")<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC; also the prefix of every public gateway (<name>-<zone>) and of unnamed private networks (<name>-<key>) | `string` | n/a | yes |
| <a name="input_private_networks"></a> [private\_networks](#input\_private\_networks) | Private networks keyed by name; a network without name is named <name>-<key>; subnets are given in network address form (for example 10.0.1.0/24) | <pre>map(object({<br/>    name                             = optional(string)           # Network name (defaults to <name>-<key>)<br/>    ipv4_subnet                      = optional(string)           # IPv4 CIDR (defaults to auto-assigned /22)<br/>    ipv6_subnet                      = optional(string)           # IPv6 CIDR (defaults to auto-assigned /64)<br/>    tags                             = optional(list(string), []) # Network-specific tags, merged with tags<br/>    enable_default_route_propagation = optional(bool)             # Default route propagation (null keeps the provider default)<br/>  }))</pre> | <pre>{<br/>  "default": {}<br/>}</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project UUID that owns the resources (null uses the provider's default project) | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the regional resources are created (null uses the provider's region) | `string` | `null` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Custom VPC routes keyed by name; each sets exactly one next hop: nexthop\_private\_network (a key of private\_networks), nexthop\_resource\_id or nexthop\_vpc\_connector\_id; destination is given in network address form | <pre>map(object({<br/>    destination              = string<br/>    description              = optional(string)<br/>    tags                     = optional(list(string), [])<br/>    nexthop_private_network  = optional(string)<br/>    nexthop_resource_id      = optional(string)<br/>    nexthop_vpc_connector_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the VPC, private networks, gateways, gateway IPs, IPAM IPs and routes | `list(string)` | `[]` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Availability zones that each get a public gateway (must belong to region if both are specified) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_control_list_ids"></a> [access\_control\_list\_ids](#output\_access\_control\_list\_ids) | VPC Access Control List IDs by IP family (ipv4, ipv6); empty if no ACL is created |
| <a name="output_gateway_flexible_ip_addresses"></a> [gateway\_flexible\_ip\_addresses](#output\_gateway\_flexible\_ip\_addresses) | Public IP addresses reserved by the module, by zone (existing IPs from gateway.flexible\_ip\_ids are not listed) |
| <a name="output_gateway_flexible_ip_ids"></a> [gateway\_flexible\_ip\_ids](#output\_gateway\_flexible\_ip\_ids) | IDs of the flexible IPs reserved by the module, by zone (existing IPs from gateway.flexible\_ip\_ids are not listed) |
| <a name="output_gateway_ids"></a> [gateway\_ids](#output\_gateway\_ids) | Public gateway IDs by zone |
| <a name="output_gateway_network_ids"></a> [gateway\_network\_ids](#output\_gateway\_network\_ids) | Gateway network attachment IDs by network-zone pair (e.g., web-fr-par-1) |
| <a name="output_ipam_ip_addresses"></a> [ipam\_ip\_addresses](#output\_ipam\_ip\_addresses) | IPAM IP addresses by network-zone pair |
| <a name="output_ipam_ip_ids"></a> [ipam\_ip\_ids](#output\_ipam\_ip\_ids) | IPAM IP resource IDs by network-zone pair |
| <a name="output_pat_rule_ids"></a> [pat\_rule\_ids](#output\_pat\_rule\_ids) | Port forwarding rule IDs by rule key |
| <a name="output_private_network_ids"></a> [private\_network\_ids](#output\_private\_network\_ids) | Private network IDs by network key |
| <a name="output_private_network_ipv4_cidrs"></a> [private\_network\_ipv4\_cidrs](#output\_private\_network\_ipv4\_cidrs) | First IPv4 CIDR block by network key (null if the network has none) |
| <a name="output_private_network_ipv6_cidrs"></a> [private\_network\_ipv6\_cidrs](#output\_private\_network\_ipv6\_cidrs) | IPv6 CIDR blocks by network key (empty list if the network has none) |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | VPC route IDs by route key |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC resource identifier |
<!-- END_TF_DOCS -->

## Contributing

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code.

1. Run `mise install` and `pre-commit install` once, and `mise run spec-setup` once per machine to register the standards stores.
2. Create a branch from `develop` and make the change; run `pre-commit run -a` and `mise run spec-validate`.
3. Write commit subjects that read as CHANGELOG lines: `CHANGELOG.md` is generated by git-cliff (`mise run changelog`) at release, not edited by hand.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-network?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-network/-/releases
