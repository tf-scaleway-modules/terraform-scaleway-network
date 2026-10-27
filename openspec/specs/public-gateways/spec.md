# public-gateways Specification

## Purpose
Per-zone public gateways with flexible IPs, bastion, SMTP, masquerade, IPAM IPs and gateway-network attachments.

## Requirements

### Requirement: One gateway per zone
When `enable_gateway` (default `true`) is true, the module SHALL create one `scaleway_vpc_public_gateway` per distinct non-empty zone of `vpc_zones`, keyed by zone, named `vpc_name`, of type `gateway_type` (default `VPC-GW-S`), tagged with `vpc_tags`. It SHALL create none when `enable_gateway` is false or `vpc_zones` is empty.

#### Scenario: Two zones
- **WHEN** `vpc_zones = ["fr-par-1", "fr-par-2"]`
- **THEN** `gateway_ids` has the keys `fr-par-1` and `fr-par-2`

#### Scenario: Gateway disabled
- **WHEN** `enable_gateway = false`
- **THEN** no gateway, flexible IP, IPAM IP or gateway network is planned

#### Scenario: No zones
- **WHEN** `vpc_zones = []`
- **THEN** no gateway, flexible IP, IPAM IP or gateway network is planned

### Requirement: Gateway type validation
`gateway_type` SHALL be either `VPC-GW-S` or `VPC-GW-M`.

#### Scenario: Unsupported type
- **WHEN** `gateway_type = "VPC-GW-L"`
- **THEN** the plan fails with "Gateway type must be either 'VPC-GW-S' or 'VPC-GW-M'."

#### Scenario: Medium type
- **WHEN** `gateway_type = "VPC-GW-M"`
- **THEN** the gateways are planned with that type

### Requirement: Flexible IP
When `gateway_reserve_flexible_ip` (default `true`) and the gateway are enabled, the module SHALL reserve one `scaleway_vpc_public_gateway_ip` per zone and attach it to the gateway of that zone. When it is false, the gateways SHALL use `gateway_existing_flexible_ip_id` (default null). When it is true, the reserved IPs are used and `gateway_existing_flexible_ip_id` is ignored.

#### Scenario: Reserved IPs
- **WHEN** `gateway_reserve_flexible_ip = true` with two zones
- **THEN** `gateway_flexible_ip_ids` and `gateway_flexible_ip_addresses` each have one entry per zone

#### Scenario: Existing IP
- **WHEN** `gateway_reserve_flexible_ip = false` and `gateway_existing_flexible_ip_id` is set
- **THEN** no flexible IP is reserved and the gateways use the given IP ID

### Requirement: SSH bastion
The module SHALL set `bastion_enabled` on the gateways from `enable_bastion` (default `false`), the bastion port from `bastion_ssh_port` (default `61000`) and the allowed ranges from `bastion_allowed_ip_ranges` (default `["0.0.0.0/0"]`).

#### Scenario: Bastion disabled by default
- **WHEN** `enable_bastion` is not set
- **THEN** the gateways are planned with the bastion disabled

#### Scenario: Port out of range
- **WHEN** `bastion_ssh_port = 70000`
- **THEN** the plan fails with "Bastion SSH port must be between 1 and 65535."

#### Scenario: Port zero
- **WHEN** `bastion_ssh_port = 0`
- **THEN** the plan fails with the same error message

#### Scenario: Bastion enabled
- **WHEN** `enable_bastion = true`, `bastion_ssh_port = 2222` and `bastion_allowed_ip_ranges = ["203.0.113.0/24"]`
- **THEN** the gateways are planned with the bastion on port 2222 limited to that range

### Requirement: SMTP and SSH key refresh
The module SHALL pass `gateway_enable_smtp` (default `false`) to the gateways' `enable_smtp` and `gateway_refresh_ssh_keys` (string, default null) to their `refresh_ssh_keys`.

#### Scenario: SMTP enabled
- **WHEN** `gateway_enable_smtp = true`
- **THEN** the gateways are planned with SMTP enabled

#### Scenario: Refresh trigger changed
- **WHEN** `gateway_refresh_ssh_keys` changes from `"1"` to `"2"`
- **THEN** the gateways are planned with the new `refresh_ssh_keys` value

### Requirement: Gateway attachments through IPAM
For every pair of a private network key and a gateway zone, the module SHALL create one IPv4 `scaleway_ipam_ip` sourced from that network and one `scaleway_vpc_gateway_network` connecting the gateway of that zone to that network, with masquerade from `gateway_enable_masquerade` (default `true`) and a default route pushed through the IPAM IP. Both are keyed `<network>-<zone>`.

#### Scenario: Two networks, two zones
- **WHEN** networks `web` and `app` and zones `fr-par-1` and `fr-par-2`
- **THEN** `gateway_network_ids`, `ipam_ip_ids` and `ipam_ip_addresses` each have four entries such as `web-fr-par-1`

#### Scenario: Masquerade disabled
- **WHEN** `gateway_enable_masquerade = false`
- **THEN** the gateway networks are planned with masquerade disabled

#### Scenario: Gateway disabled
- **WHEN** `enable_gateway = false`
- **THEN** no IPAM IP and no gateway network is planned
