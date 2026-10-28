## Why

Writing the `adopt-openspec` baseline surfaced six gaps. Each was verified against the code; none needs a breaking change.

## What Changes

| # | Issue | Decision | Breaking |
|---|-------|----------|----------|
| 1 | `network_ipv6_cidrs` calls `coalescelist` on `ipv6_subnets[*].subnet`, which errors on an empty list | Code fix: drop `coalescelist`; a network without IPv6 subnet yields an empty list | No (patch: it only fixes a plan that failed) |
| 2 | `gateway_existing_flexible_ip_id` is documented as overriding `gateway_reserve_flexible_ip`, but the reserved IP wins | Doc fix plus `check` warning when both are set. Making the existing ID win would silently swap the IP of configs that already run | No (patch) |
| 3 | Gateways in several zones share the name `vpc_name`; `vpc_name` is described as a prefix | Doc fix only: describe `vpc_name` as the exact VPC and gateway name. Renaming would update every existing gateway for cosmetic gain | No (patch) |
| 4 | `access_control_list_rules` protocol and action are not validated although only `ANY/TCP/UDP/ICMP` and `accept/drop` are accepted by Scaleway | Code fix: validation, active only when `enable_access_control_list` is true, so it rejects only configs that would fail at apply. Rules given while the ACL is disabled stay ignored (described) | No (patch) |
| 5 | README release badge and link point to `scaleway-vpc` | Doc fix | No (patch) |
| 6 | `vpc_zones` validation has no test | Tests only (first `tests/main.tftest.hcl`); validation unchanged | No (patch) |

Semver: **patch**. Nothing is removed or renamed, no default changes, no resource address or argument changes, so no state migration. No secret is added; state content is unchanged.

Standards applied: `terraform-versioning`, `terraform-variables`, `terraform-outputs`, `terraform-testing`, `terraform-security` (check block), quality non-negotiables of `AGENTS.md`.

## Capabilities

### Modified Capabilities
- `access-control-list`: protocol/action validation, rules-ignored wording
- `public-gateways`: flexible IP precedence check, gateway name wording
- `private-networks`: IPv6 output with no IPv6 subnet
- `vpc`: zones validation scenarios covered by tests

## Impact

`variables.tf`, `outputs.tf`, `main.tf` (check block), `README.md`, `tests/main.tftest.hcl` (new), `examples/complete`. Input count stays 24.
