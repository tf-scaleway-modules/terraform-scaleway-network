## Why

v1.3.0 deprecated the two VPC routing flags and deferred everything that needed a major bump. The module still carries 24 flat, theme-prefixed inputs (`vpc_*`, `gateway_*`, `bastion_*`, `access_control_list_*`), a project lookup through `organization_id` + `project_name`, two dual inputs (reserve vs existing flexible IP, with a warning `check`), an ACL limited to one IP family and no way to declare custom routes or port forwarding. A major release is allowed, so v2.0.0 moves to provider `~> 2.89`, removes the deprecated inputs, collapses the flat inputs into objects, aligns the module with the cross-module conventions (`project_id`, `region`, `tags`, `name`) and adds the missing network features.

## What Changes

Gap analysis against the 2.89.0 schema (`/tmp/scw-schema/schema-2.89.0.json`), per resource. Only `scaleway_vpc` changed since 2.86 (deprecations, already handled in v1.3.0). `scaleway_vpc_private_network` `is_regional` / `zone`, `scaleway_vpc_public_gateway` `move_to_ipam` / `upstream_dns_servers` and `scaleway_vpc_gateway_network` `enable_dhcp` / `dhcp_id` / `static_address` / `cleanup_dhcp` are deprecated and stay unused.

### Adopted features

| # | Resource / argument | Since | Module surface |
|---|---------------------|-------|----------------|
| 1 | `scaleway_vpc_route` (`destination`, `description`, `tags`, one of `nexthop_private_network_id`, `nexthop_resource_id`, `nexthop_vpc_connector_id`) | resource 2.45.0, connector next hop 2.73.0 | `routes` map; next hop can name a module private network by key |
| 2 | `scaleway_vpc_public_gateway_pat_rule` (port forwarding) | 2.2.0 | `gateway.pat_rules` map |
| 3 | Dual-stack ACL: one `scaleway_vpc_acl` per IP family (`is_ipv6`) | 2.52.0 | `access_control_list.ipv4` and `.ipv6` |
| 4 | Per-zone existing flexible IPs (`ip_id` per gateway) | gateway `ip_id` since 2.x | `gateway.flexible_ip_ids` map zone → IP ID; zones not listed get a reserved IP |
| 5 | Gateway types `VPC-GW-L` and `VPC-GW-XL` (Scaleway offer; the provider takes the type as a free string) | n/a | accepted by `gateway.type` |
| 6 | `region` set on the ACL (it was never passed, so a non-default `vpc_region` placed it in the provider's region) | fix | ACL follows `region` |
| 7 | Tags on routes and merged (distinct) tags on every taggable resource | n/a | `tags` + per-item `tags` |

### Breaking changes

| # | Change | Consumer edit |
|---|--------|---------------|
| 1 | Remove `vpc_enable_routing`, `vpc_enable_custom_routes` and `check "vpc_deprecated_routing_flags"` (provider always enables both) | delete the two inputs |
| 2 | Remove `organization_id`, `project_name` and `data.scaleway_account_project`; add `project_id` (string, null = provider default project) | pass the project UUID as `project_id`, or drop it to use the provider project |
| 3 | `vpc_region` → `region`, `vpc_zones` → `zones` | rename |
| 4 | `vpc_name` → `name`; VPC keeps `name`, gateways become `<name>-<zone>` (was `<name>` in every zone) | rename; gateway rename is an in-place update |
| 5 | `vpc_tags` → `tags` | rename |
| 6 | `vpc_enable_transitivity` → `enable_transitivity` | rename |
| 7 | `network_private_networks` → `private_networks`; a network without `name` is named `<name>-<key>` (was a provider-generated name) | rename; unnamed existing networks are renamed in place, set `name` to keep the old one |
| 8 | `enable_gateway`, `gateway_*`, `enable_bastion`, `bastion_*` → one nullable object `gateway` (`type`, `flexible_ip_ids`, `enable_masquerade`, `enable_smtp`, `refresh_ssh_keys`, `bastion`, `pat_rules`); `gateway = null` replaces `enable_gateway = false`; `bastion = null` replaces `enable_bastion = false` | map each input to its attribute (table in README) |
| 9 | `gateway_reserve_flexible_ip` + `gateway_existing_flexible_ip_id` + `check "gateway_flexible_ip"` → `gateway.flexible_ip_ids` (zone → IP ID). `reserve = false` without an ID (gateway left without a managed IP) is no longer expressible | `reserve=false, existing=X` on zone Z → `flexible_ip_ids = { Z = X }` |
| 10 | `bastion_allowed_ip_ranges` loses its `0.0.0.0/0` default: required whenever `gateway.bastion` is set (`terraform-security` network defaults) | list the allowed CIDRs |
| 11 | `enable_access_control_list`, `access_control_list_*` → nullable object `access_control_list` with `ipv4` / `ipv6` families, each `default_policy` + `rules`; no default HTTP rule (rules default `[]`); rule ports default `0`; `scaleway_vpc_acl.this[0]` → `this["ipv4"]` | wrap existing settings in `ipv4 = {...}` (or `ipv6 = {...}` + one `state mv`, see design) |
| 12 | Outputs `network_private_network_ids`, `network_ipv4_cidrs`, `network_ipv6_cidrs` → `private_network_ids`, `private_network_ipv4_cidrs`, `private_network_ipv6_cidrs`; `access_control_list_id` → `access_control_list_ids` (map by family) | rename; read `["ipv4"]` for the former value |

### Simplifications

| # | Item |
|---|------|
| 1 | 24 inputs → 10 (`project_id`, `region`, `zones`, `name`, `tags`, `enable_transitivity`, `private_networks`, `gateway`, `access_control_list`, `routes`); only `name` is required |
| 2 | `data.tf` removed; `locals.tf` loses `common_tags` and the `compact()` workaround (empty zone strings are rejected by validation instead) |
| 3 | Both `check` blocks removed (their cases are no longer expressible); validation blocks replace them |
| 4 | `count` on the ACL replaced by `for_each` over the families |
| 5 | Provider floor `~> 2.86` → `~> 2.89` in the module and in both examples |

### Deferred / rejected

| Item | Reason |
|------|--------|
| `scaleway_vpc_ingress_rule`, `scaleway_vpc_connector` (2.77.0 / 2.71.0) | need a peered or connected second VPC that this single-VPC module does not own |
| `ipv6_subnet` → list (`ipv6_subnets` is repeatable) | still a niche need, API-assigned set entries; scalar kept |
| IPv6 `scaleway_ipam_ip`, static `address` | the gateway attachment is IPv4-only; docs advise against static IPs |
| Dropping `scaleway_ipam_ip` and letting the API allocate in `ipam_config` | would replace every gateway network (NAT outage) and lose the stable address when an attachment is recreated |
| `scaleway_vpc_public_gateway_ip` `reverse`, `*_reverse_dns` | one reverse name per zone IP needs a map input; low value here |
| `scaleway_vpc_public_gateway_dhcp(_reservation)` | deprecated (IPAM replaces DHCP) |
| Safer default ACL policy `drop` | would silently lock out callers that rely on the current `accept` |
| Deriving `region` from `zones` when null | hidden coupling; null stays "provider default" |
| Data sources (`scaleway_vpc_routes`, `scaleway_ipam_ips`, …) | the module manages, not reads |
| Write-only / ephemeral secrets | no secret-bearing argument in this module |

## Capabilities

### New Capabilities
- `vpc-routes`: custom VPC routes with a next hop

### Modified Capabilities
- `module-contract`: provider floor, `project_id`, new input and output surface, no project lookup
- `vpc`: `region`, `name`, `tags`, `enable_transitivity`, zones validation, routing flags removed
- `private-networks`: renamed input, default name, distinct tag merge, subnet validation, renamed outputs
- `public-gateways`: `gateway` object, per-zone flexible IPs, bastion without default range, PAT rules, types L/XL
- `access-control-list`: `access_control_list` object with IPv4 and IPv6 families, rule validation

## Semver

**Major** (v1.3.0 → v2.0.0, `terraform-versioning`): inputs and outputs removed or renamed, defaults changed, resource address changed. Input/output changes: every row of the Breaking table. Types changing: `gateway` and `access_control_list` are new object types replacing scalars and lists; `private_networks` keeps the map shape of the old input, `zones` and `tags` keep `list(string)`. Defaults changing: `bastion` allowed ranges (default removed), ACL default rule (removed), private network name (generated → `<name>-<key>`), gateway name (`<name>` → `<name>-<zone>`). Meaning changing: `project_id` replaces the name lookup. New outputs: `route_ids`, `pat_rule_ids`.

## State

No resource is replaced for an unchanged setup: private networks, gateways, flexible IPs, IPAM IPs and gateway networks keep their keys. In-place updates: gateway names, unnamed private network names. One `moved` block: `scaleway_vpc_acl.this[0]` → `this["ipv4"]`. New resources (routes, PAT rules, IPv6 ACL) appear only when requested. The removed data source leaves no state. No secret lands in state; no secret-bearing input exists, so write-only arguments do not apply (`terraform-security`).

## Impact

Files: `versions.tf`, `variables.tf`, `main.tf`, `locals.tf`, `outputs.tf`, `data.tf` (deleted), `README.md` ("Upgrading from v1 to v2" replaces "Upgrade notes"; terraform-docs block regenerated), `tests/main.tftest.hcl`, `examples/minimal`, `examples/complete` (incl. their `versions.tf`). Specs: five modified, one new. Standards applied: `terraform-versioning`, `terraform-variables`, `terraform-providers`, `terraform-security` (bastion default, validated CIDRs), `terraform-testing`, `quality-simplicity`, `quality-production-readiness` (empty second plan).
