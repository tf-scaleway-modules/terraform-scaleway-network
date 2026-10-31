## Why

Scaleway provider 2.88.0 deprecated `scaleway_vpc` `enable_routing` and `enable_custom_routes_propagation` ("always enabled on newly created VPCs and cannot be disabled, removed in a future major version"). The module sets both on every VPC from `vpc_enable_routing` and `vpc_enable_custom_routes` (default `true`), so every consumer now sees two provider deprecation warnings they cannot act on. The module resolves `~> 2.86` to 2.89.0 today; a gap analysis of the seven resources it manages against 2.89.0 also found one routing argument that is available since 2.86 and not exposed yet.

## What Changes

Provider delta 2.86.0 → 2.89.0 for the managed resources (docs diffed per resource): only `scaleway_vpc` changed (the deprecation above). `vpc_acl`, `vpc_gateway_network`, `vpc_private_network`, `vpc_public_gateway`, `vpc_public_gateway_ip` and `ipam_ip` docs are identical. Other items in the range need no module work: 2.84.0 (VPC retry on transient IAM 403, private network delete timeout 2 min) is a provider-side fix within the floor; 2.87.0 `srn` on `data.scaleway_account_project` is not used.

Adopted:

| # | Item | Introduced in | Decision | Breaking |
|---|------|---------------|----------|----------|
| 1 | Stop sending deprecated `enable_routing` / `enable_custom_routes_propagation`. `vpc_enable_routing` and `vpc_enable_custom_routes` stay for one version, default `true` → `null`, deprecated in their description, passed to the VPC only when set; a `check` warns when either is set | deprecated in 2.88.0 (both arguments are Optional+Computed in 2.86.0 and 2.89.0) | Deprecate, remove in the next major | No (minor, see Semver) |
| 2 | `enable_default_route_propagation` as an optional per-network attribute of `network_private_networks` (default `null` = provider default, sent only when set) | 2.86.0 or earlier (present in the 2.86.0 docs and schema) | Add | No (minor) |

Deferred or rejected (one line each, revisit on demand):

- `scaleway_vpc_route` custom routes: next-hop resources (instance NICs, bare metal) live outside this module and the VPC-wide propagation flag is itself being deprecated; a route input would need its own design.
- `scaleway_vpc_public_gateway_pat_rule`, gateway `upstream_dns_servers` (deprecated), `dhcp_*` / `static_address` (deprecated): port forwarding is a separate feature with per-rule inputs; deprecated arguments must not be adopted.
- `scaleway_vpc_public_gateway_ip` `reverse` and the `*_reverse_dns` resources: one reverse name cannot fit a per-zone IP set without a map input; value is low for a network module.
- `scaleway_ipam_ip` `address` (static IPs) and `is_ipv6` / IPv6 IPAM IPs: provider docs advise against static IPs; the gateway attachment only needs an IPv4 IPAM IP.
- Several IPv6 subnets per private network (`ipv6_subnets` is repeatable): turning `ipv6_subnet` into a list is a type change, so a major bump for a niche need.
- Private network `is_regional` / `zone` and `scaleway_vpc_connector`: deprecated or out of scope for a single-VPC module.
- Warning on `bastion_allowed_ip_ranges = ["0.0.0.0/0"]` (terraform-security "Network defaults"): not provider-driven; changing the default is major. Candidate for its own change.
- Raising `versions.tf` to `~> 2.89`: not needed (see Semver).

Semver: **minor** per `terraform-versioning`. Nothing is removed or renamed, no resource address changes, and no default alters a resource: `vpc_enable_routing` / `vpc_enable_custom_routes` keep their types and the default `true` → `null` only stops sending an argument the provider ignores and computes (existing state already reads `true`, so the plan stays empty). The provider floor stays `~> 2.86` because nothing adopted needs an argument absent from 2.86.0; a raised floor would be a major bump and is not taken. Inputs changed in meaning: `vpc_enable_routing` and `vpc_enable_custom_routes` (default `true` → `null`, deprecated). New attribute: `network_private_networks[*].enable_default_route_propagation`. No output changes; input count stays 24 (the new attribute lives inside an existing map object).

State: no resource is replaced. Existing VPCs keep `enable_routing = true` / `enable_custom_routes_propagation = true` in state and the plan stays empty. Existing private networks read back `enable_default_route_propagation` from the API; with `null` the plan stays empty. No secret-bearing input is added; nothing secret lands in state.

Standards applied: `terraform-versioning` (classification, breaking change checklist: old inputs kept one version with a deprecation description), `terraform-variables` (optional `null` default means provider default, deprecation in the description), `terraform-providers` (floor stays need-driven), `terraform-testing` (rejected or warned input per check), `terraform-security` (check block for a legal but deprecated configuration), quality non-negotiables of `AGENTS.md` (`quality-simplicity`: stop sending ignored arguments; `quality-production-readiness`: empty second plan, upgrade notes).

## Capabilities

### Modified Capabilities
- `vpc`: routing flags are deprecated, default to unset, and are sent only when set; a check warns when they are set
- `private-networks`: a network may set `enable_default_route_propagation`

## Impact

`variables.tf` (two defaults and descriptions, `network_private_networks` type), `main.tf` (comments, `check "vpc_deprecated_routing_flags"`, `enable_default_route_propagation` on the private network), `README.md` (terraform-docs block plus a short upgrade note), `tests/main.tftest.hcl`, `examples/complete` (drop the two deprecated inputs, set the new attribute on one network). `versions.tf` unchanged. Removal of the two inputs is announced for the next major release together with the provider's own removal.
