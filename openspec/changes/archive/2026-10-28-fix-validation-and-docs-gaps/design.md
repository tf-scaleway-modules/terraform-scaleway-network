## Decisions

- **IPv6 output**: `network_ipv6_cidrs` value becomes `v.ipv6_subnets[*].subnet`. Output only; no resource change, no state migration.
- **Flexible IP**: no behaviour change. A `check "gateway_flexible_ip"` (OpenTofu >= 1.10 / Terraform >= 1.5, within the floor) asserts `!(enable_gateway && gateway_reserve_flexible_ip && gateway_existing_flexible_ip_id != null)`; the failure only warns. The variable description now says the ID is used only when `gateway_reserve_flexible_ip` is false. Avoids a perpetual diff or IP swap for existing users.
- **Gateway name**: unchanged (`name = var.vpc_name`). Appending the zone would rename live gateways in place; the sharing of a name across zones is legal in Scaleway. Only the `vpc_name` description changes.
- **ACL validation**: one `validation` on `access_control_list_rules`: `!var.enable_access_control_list || alltrue([for r in rules : contains(["ANY","TCP","UDP","ICMP"], r.protocol) && contains(["accept","drop"], r.action)])`. It references another variable (allowed since OpenTofu 1.9, floor is 1.10.7). Gated on the enable flag so configs with the ACL disabled that worked still work. Values come from the Scaleway VPC ACL API enum (protocol `ANY`, `TCP`, `UDP`, `ICMP`; action `accept`, `drop`).
- **Tests**: `mock_provider "scaleway"` with `override_data` for the project; `command = plan`. One run per validation failure, one per check, happy paths.
- **Provider**: no version change (`~> 2.86`).
