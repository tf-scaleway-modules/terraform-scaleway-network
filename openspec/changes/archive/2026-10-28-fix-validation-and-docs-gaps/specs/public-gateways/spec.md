## MODIFIED Requirements

### Requirement: One gateway per zone
When `enable_gateway` (default `true`) is true, the module SHALL create one `scaleway_vpc_public_gateway` per distinct non-empty zone of `vpc_zones`, keyed by zone, named exactly `vpc_name` (the same name in every zone), of type `gateway_type` (default `VPC-GW-S`), tagged with `vpc_tags`. It SHALL create none when `enable_gateway` is false or `vpc_zones` is empty.

#### Scenario: Two zones
- **WHEN** `vpc_zones = ["fr-par-1", "fr-par-2"]`
- **THEN** `gateway_ids` has the keys `fr-par-1` and `fr-par-2`

#### Scenario: Gateway disabled
- **WHEN** `enable_gateway = false`
- **THEN** no gateway, flexible IP, IPAM IP or gateway network is planned

#### Scenario: No zones
- **WHEN** `vpc_zones = []`
- **THEN** no gateway, flexible IP, IPAM IP or gateway network is planned

#### Scenario: Gateway name
- **WHEN** `vpc_name = "core"` and two zones
- **THEN** both gateways are planned with the name `core`

### Requirement: Flexible IP
When `gateway_reserve_flexible_ip` (default `true`) and the gateway are enabled, the module SHALL reserve one `scaleway_vpc_public_gateway_ip` per zone and attach it to the gateway of that zone. When it is false, the gateways SHALL use `gateway_existing_flexible_ip_id` (default null). When it is true, the reserved IPs are used and `gateway_existing_flexible_ip_id` is ignored; a `check` SHALL warn (without failing the plan) when the gateway is enabled, `gateway_reserve_flexible_ip` is true and `gateway_existing_flexible_ip_id` is set.

#### Scenario: Reserved IPs
- **WHEN** `gateway_reserve_flexible_ip = true` with two zones
- **THEN** `gateway_flexible_ip_ids` and `gateway_flexible_ip_addresses` each have one entry per zone

#### Scenario: Existing IP
- **WHEN** `gateway_reserve_flexible_ip = false` and `gateway_existing_flexible_ip_id` is set
- **THEN** no flexible IP is reserved and the gateways use the given IP ID

#### Scenario: Both reserve and existing IP set
- **WHEN** `gateway_reserve_flexible_ip = true`, `gateway_existing_flexible_ip_id` is set and the gateway is enabled
- **THEN** the reserved IPs are used and the plan warns that the existing IP ID is ignored
