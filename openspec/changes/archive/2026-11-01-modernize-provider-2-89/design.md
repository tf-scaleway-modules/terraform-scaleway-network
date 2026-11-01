# Design

## Context

v1.3.0: seven resources (`scaleway_vpc`, `scaleway_vpc_acl`, `scaleway_vpc_private_network`, `scaleway_vpc_public_gateway_ip`, `scaleway_vpc_public_gateway`, `scaleway_ipam_ip`, `scaleway_vpc_gateway_network`), 24 flat inputs, a project data source, two `check` blocks. Provider `~> 2.86` already resolves to 2.89.0; the 2.89.0 schema was read for every resource above and its neighbours (see the proposal's gap analysis). Observed defect: `scaleway_vpc_acl.this` never receives `region`, so with a `vpc_region` other than the provider region the ACL is addressed in the wrong region. `required_version` stays `>= 1.10.7`: nothing here needs write-only arguments, ephemeral values or newer language features (`optional()` defaults, cross-variable validation, `moved` are all available).

## Goals / Non-Goals

**Goals**
- Provider `~> 2.89`; no deprecated argument sent; module conventions (`project_id`, `region`, `tags`, `name`, objects with `optional()`, `for_each`).
- Add routes, port forwarding and a dual-stack ACL; make the bastion and flexible IP inputs impossible to misconfigure.
- Unchanged infrastructure plans empty after the upgrade apart from the documented in-place renames.

**Non-Goals**
- Peering (`scaleway_vpc_ingress_rule`, `scaleway_vpc_connector`), reverse DNS, DHCP, static IPAM addresses, data sources (see the proposal).
- Write-only / ephemeral inputs: no secret in this module.

## Decisions

### 1. Provider and tooling
`versions.tf` and both `examples/*/versions.tf`: `scaleway/scaleway ~> 2.89`. 2.90.0 is tagged on GitHub only; `~> 2.89` accepts it once published and its only item (computed `srn` on an ephemeral API key) is irrelevant. `required_version` unchanged. Alternative: keep `~> 2.86`, rejected because the fixed decision for this release is the 2.89 floor and the new resources are exercised against 2.89 schemas.

### 2. Project: `project_id` replaces the lookup
`variable "project_id" { type = string, default = null }` with `validation` (null or UUID regex). Passed as `project_id` to `scaleway_vpc`, `scaleway_vpc_private_network`, `scaleway_vpc_public_gateway(_ip)` and `scaleway_ipam_ip`. `data.tf` and `organization_id` are deleted: the data source only turned a name into the same UUID, and it required an organization the module does not otherwise use. Zonal-only resources without `project_id` (ACL, gateway network, PAT rule, route) inherit the project from their parent. Alternative: keep an optional `project_name`, rejected (two ways to say the same thing, an extra API read on every plan).

### 3. Location and naming
- `region` (null = provider region) on VPC, private network, ACL, IPAM IP, route (`scaleway_vpc_route.region`, `scaleway_vpc_acl.region`, `scaleway_ipam_ip.region`); `zones` (list) drives the gateway set. The "zones belong to `region`" validation is kept as is, plus rejection of empty strings, which removes the `compact()` calls. Alternative: derive the region from the zones, rejected (hidden coupling, null must mean "provider default").
- `name` (required) names the VPC; gateways are `<name>-<zone>` (names are unique per zone and readable); private networks default to `<name>-<key>` through `coalesce(each.value.name, "${var.name}-${each.key}")`. Both renames are in-place updates in the provider (name is updatable on gateway and private network); they are the only plan changes on upgrade and the README lists them. A caller who wants to keep an old generated name sets `name` on the network explicitly.
- `tags` applies to VPC, private networks, gateway IPs, gateways, IPAM IPs and routes; per-item tags are merged with `distinct(concat(var.tags, each.value.tags))`. `scaleway_vpc_acl` and `scaleway_vpc_gateway_network` have no `tags` argument; PAT rules neither.

### 4. `gateway` object
```hcl
variable "gateway" {
  type = object({
    type              = optional(string, "VPC-GW-S")
    flexible_ip_ids   = optional(map(string), {})
    enable_masquerade = optional(bool, true)
    enable_smtp       = optional(bool, false)
    refresh_ssh_keys  = optional(string)
    bastion = optional(object({
      port              = optional(number, 61000)
      allowed_ip_ranges = list(string)
    }))
    pat_rules = optional(map(object({
      zone         = string
      public_port  = number
      private_ip   = string
      private_port = number
      protocol     = optional(string, "both")
    })), {})
  })
  default = {}   # nullable: null disables the gateways
}
```
- `local.gateway_zones = var.gateway == null ? toset([]) : toset(var.zones)`; `local.network_zone_pairs` as before from `gateway_zones`; `local.reserved_ip_zones = setsubtract(gateway_zones, keys(gateway.flexible_ip_ids))`.
- `scaleway_vpc_public_gateway.this`: `ip_id = try(var.gateway.flexible_ip_ids[each.key], scaleway_vpc_public_gateway_ip.this[each.key].id)`; `bastion_enabled = var.gateway.bastion != null`, `bastion_port = try(bastion.port, null)`, `allowed_ip_ranges = try(bastion.allowed_ip_ranges, null)`. With the bastion off the two arguments are null, which the provider treats as unset (computed). Verify in the first real plan that a v1.3.0 state with `bastion_enabled = false`, `bastion_port = 61000`, `allowed_ip_ranges = ["0.0.0.0/0"]` shows no diff; if it does, send the old defaults when the bastion is off (see Risks).
- The reserve/existing pair and its warning `check` were a dual input whose existing ID applied to every zone (an IP is zonal, so it could only work for one zone). A zone → ID map removes both the check and the ambiguity. Alternative: keep two inputs, rejected (`quality-simplicity`).
- `gateway.type`: validation `contains(["VPC-GW-S", "VPC-GW-M", "VPC-GW-L", "VPC-GW-XL"], type)`. The provider takes any string; the list is the Scaleway offer (documented on the pricing page); the validation catches typos at plan time and is one line to extend.
- Bastion default range removed (`terraform-security`: no world-open default for an administrative service); `allowed_ip_ranges` is required inside `bastion` and validated non-empty with `alltrue([for c in ranges : can(cidrhost(c, 0))])`.
- Cross-attribute validation on `gateway` (same message for both): keys of `flexible_ip_ids` and every `pat_rules[*].zone` must be in `var.zones` (skipped when `gateway` is null). `can(cidrhost())` accepts IPv4 and IPv6, so ranges stay family-agnostic.
- `pat_rules`: `scaleway_vpc_public_gateway_pat_rule.this` (provider 2.2.0), `for_each = local.pat_rules` (empty when the gateway is off), `gateway_id = scaleway_vpc_public_gateway.this[each.value.zone].id`, `zone`, `private_ip`, `private_port`, `public_port`, `protocol`, `depends_on = [scaleway_vpc_gateway_network.this]` (the target IP must be reachable through an attached network). Validations: ports 1-65535, protocol in `both/tcp/udp`, unique `public_port` per zone (`length(distinct(...))` over `"zone:port"`). `protocol` is sent in lower case: the 2.89.0 provider defaults to `both`, validates the enum case-insensitively and reads back the API's lower-case value (verified in `internal/services/vpcgw/pat_rule.go`).
- Alternative for `pat_rules` placement: top-level variable, rejected because the rules cannot exist without the gateway and share its null switch.

### 5. `access_control_list` object
```hcl
variable "access_control_list" {
  type = object({
    ipv4 = optional(object({ default_policy = optional(string, "accept"), rules = optional(list(object({...})), []) }))
    ipv6 = optional(object({ ... same ... }))
  })
  default = null
}
```
- `scaleway_vpc_acl.this`, `for_each = { for k, v in { ipv4 = ..ipv4, ipv6 = ..ipv6 } : k => v if v != null }` (empty when the variable is null), `is_ipv6 = each.key == "ipv6"`, `region = var.region`, `dynamic "rules"` over `each.value.rules`. A VPC holds at most one ACL per IP family, so the two families are the natural keys (resource since 2.52.0).
- Rule object: required `source`, `destination`, `action`; optional `protocol = "ANY"` (provider doc default), `src_port_low/high`, `dst_port_low/high = 0`, `description`. `0` for both ends of a range is how the v1.3.0 example already expressed "any port" and reads back unchanged; confirmed in the real-account group.
- Validations: policy, protocol and action enums, ports `0..65535` with `low <= high`, `can(cidrhost(source, 0))` for `source` and `destination`. The v1.3.0 `enable_access_control_list ||` guard disappears: a null variable skips the checks natively.
- Default HTTP rule removed: an opened port nobody asked for is an invented, security-relevant default. `default_policy = "accept"` stays (changing it would silently lock out callers).
- Alternative: `enable_access_control_list` + `is_ipv6` + `rules` kept and only renamed, rejected (cannot express both families, the very common production case).

### 6. `routes`
`scaleway_vpc_route.this` (resource 2.45.0, `nexthop_vpc_connector_id` 2.73.0), `for_each = var.routes`, `vpc_id`, `region`, `destination`, `description`, `tags`, `nexthop_private_network_id = try(scaleway_vpc_private_network.this[each.value.nexthop_private_network].id, null)`, `nexthop_resource_id`, `nexthop_vpc_connector_id`. The private network is given by key because its ID is unknown before apply and a module cannot be fed its own output. Validations: exactly one of the three next hops (`length(compact([...])) == 1`), `can(cidrhost(destination, 0))`, `nexthop_private_network` is a key of `var.private_networks`. This answers the v1.3.0 deferral ("next-hop resources live outside the module"): external next hops are plain IDs, module-owned ones are keys. The 2.89.0 provider (`internal/services/vpc/route.go`) does not validate the next-hop combination itself (the three IDs are plain optional strings sent to the API, `description` is optional and computed, `tags` are read back only when non-empty), so the module's exactly-one rule is the only plan-time guard and matches the API's single-next-hop model.

### 7. State migration
| Address | Change | Handling |
|---|---|---|
| `scaleway_vpc.this` | none | unchanged |
| `scaleway_vpc_private_network.this["k"]` | same keys; name only for null-named networks | in-place rename |
| `scaleway_vpc_public_gateway.this["zone"]` | same keys; name `<name>` → `<name>-<zone>` | in-place rename |
| `scaleway_vpc_public_gateway_ip.this["zone"]`, `scaleway_ipam_ip.this["n-zone"]`, `scaleway_vpc_gateway_network.this["n-zone"]` | same keys | unchanged |
| `scaleway_vpc_acl.this[0]` | `count` → `for_each` | `moved { from = scaleway_vpc_acl.this[0], to = scaleway_vpc_acl.this["ipv4"] }` |
| `data.scaleway_account_project.project` | removed | nothing in state to migrate |

A `moved` block cannot branch on the former `access_control_list_is_ipv6`, so it assumes IPv4 (the default and the example). An IPv6-only consumer runs once, before the upgrade apply, `tofu state mv 'module.<x>.scaleway_vpc_acl.this[0]' 'module.<x>.scaleway_vpc_acl.this["ipv6"]'` (in the README upgrade section); skipping it would plan a replacement of the ACL (a window without filtering), which the plan output makes visible.

The README documents two equivalent forms: a root-module `moved { from = module.<n>.scaleway_vpc_acl.this["ipv4"], to = module.<n>.scaleway_vpc_acl.this["ipv6"] }` that chains after the module's own `moved` (verified on OpenTofu 1.11.6 against a git-sourced module), or the `tofu state mv` of `this[0]` to `this["ipv6"]`. Checked against the 2.89.0 provider source: `scaleway_vpc_acl` has no `ForceNew` argument and does not read `is_ipv6` back, so an unmoved IPv6 state is destroyed at `this["ipv4"]` (its delete resets the IPv4 ACL to accept) and `this["ipv6"]` is created. The `moved` block stays one release cycle and is removed in a later minor.

### 8. Perpetual-diff avoidance
Optional arguments with provider-side defaults are omitted when null (`enable_default_route_propagation`, `refresh_ssh_keys`, bastion arguments, rule `description`), so Computed values are kept. Send what the server reads back: lower-case PAT protocol, ACL port `0`, CIDRs as written by the caller (a non-canonical CIDR such as `10.0.0.1/24` would read back as `10.0.0.0/24`; the validation could not catch it without a canonical-form rule, so the variable descriptions state "network address form"). Each new resource gets a second-plan check in the real-account group.

### 9. Outputs
Renames and additions are listed in the proposal. `access_control_list_ids`, `route_ids` and `pat_rule_ids` are maps keyed like their inputs. `gateway_flexible_ip_*` stay limited to IPs reserved by the module (documented in their description); existing IPs are the caller's own.

## Risks / Trade-offs

- [Bastion off sends null where v1.3.0 sent `61000` and `0.0.0.0/0`] → in-place diff or none depending on the provider's Computed handling; first real plan decides; fallback is to keep sending the old values when the bastion is off. Low impact (the bastion is disabled).
- [`state mv` is a manual step for IPv6-only ACL callers] → documented, and an unmoved state only produces a visible replacement plan.
- [Gateway and private network renames] → in-place; the README tells callers how to pin the old name.
- [`depends_on` on PAT rules adds ordering that hides a missing network] → accepted, safer than a race at apply.
- [GW types L/XL not in the provider docs] → type is a free string in the schema; validated against the Scaleway offer; real-account check applies an L gateway only if quota allows (otherwise skipped and reported).
- [Rejected: 2.90.0 floor] → not on the registries.
