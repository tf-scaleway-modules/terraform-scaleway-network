## MODIFIED Requirements

### Requirement: One gateway per zone
The module SHALL create one `scaleway_vpc_public_gateway` per distinct zone of `zones`, keyed by zone, named `<name>-<zone>`, of type `gateway.type`, tagged with `tags`, unless `gateway` is null or `zones` is empty. `gateway` (nullable object, default `{}`) groups every gateway setting; `gateway = null` replaces the former `enable_gateway = false`.

#### Scenario: Two zones
- **WHEN** `zones = ["fr-par-1", "fr-par-2"]`
- **THEN** `gateway_ids` has the keys `fr-par-1` and `fr-par-2`

#### Scenario: Gateway disabled
- **WHEN** `gateway = null`
- **THEN** no gateway, flexible IP, IPAM IP, gateway network or PAT rule is planned

#### Scenario: No zones
- **WHEN** `zones = []`
- **THEN** no gateway, flexible IP, IPAM IP, gateway network or PAT rule is planned

#### Scenario: Gateway name
- **WHEN** `name = "core"` and the zone `fr-par-1`
- **THEN** the gateway is planned with the name `core-fr-par-1`

### Requirement: Gateway type validation
`gateway.type` (default `VPC-GW-S`) SHALL be one of `VPC-GW-S`, `VPC-GW-M`, `VPC-GW-L` or `VPC-GW-XL`.

#### Scenario: Unsupported type
- **WHEN** `gateway = { type = "VPC-GW-XXL" }`
- **THEN** the plan fails with "Gateway type must be one of 'VPC-GW-S', 'VPC-GW-M', 'VPC-GW-L' or 'VPC-GW-XL'."

#### Scenario: Medium type
- **WHEN** `gateway = { type = "VPC-GW-M" }`
- **THEN** the gateways are planned with that type

#### Scenario: Large type
- **WHEN** `gateway = { type = "VPC-GW-L" }`
- **THEN** the gateways are planned with that type

### Requirement: Flexible IP
The module SHALL attach to the gateway of each zone the IP given in `gateway.flexible_ip_ids` (map zone → IP ID, default `{}`), and SHALL reserve one `scaleway_vpc_public_gateway_ip` for every zone not in the map. Keys of the map MUST be zones of `zones`.

#### Scenario: Reserved IPs
- **WHEN** `gateway.flexible_ip_ids` is empty and there are two zones
- **THEN** `gateway_flexible_ip_ids` and `gateway_flexible_ip_addresses` each have one entry per zone

#### Scenario: Existing IP
- **WHEN** `gateway = { flexible_ip_ids = { "fr-par-1" = "<id>" } }` and `zones = ["fr-par-1"]`
- **THEN** no flexible IP is reserved and the gateway uses the given IP ID

#### Scenario: Existing IP in one zone
- **WHEN** `gateway = { flexible_ip_ids = { "fr-par-1" = "<id>" } }` and two zones
- **THEN** `fr-par-1` uses the given IP, no IP is reserved for it, and `fr-par-2` gets a reserved IP

#### Scenario: Key outside the zones
- **WHEN** `flexible_ip_ids` has the key `nl-ams-1` and `zones = ["fr-par-1"]`
- **THEN** the plan fails with "gateway.flexible_ip_ids keys, pat_rules zones and the bastion must refer to zones listed in zones."

### Requirement: SSH bastion
The module SHALL enable the bastion on the gateways only when `gateway.bastion` (nullable object, default `null`) is set, on `bastion.port` (default `61000`, 1-65535) and limited to `bastion.allowed_ip_ranges`, which is required, non-empty and made of valid CIDRs; there is no default range.

#### Scenario: Bastion disabled by default
- **WHEN** `gateway.bastion` is not set
- **THEN** the gateways are planned with the bastion disabled

#### Scenario: Port out of range
- **WHEN** `bastion = { port = 70000, allowed_ip_ranges = ["203.0.113.0/24"] }`
- **THEN** the plan fails with "Bastion SSH port must be between 1 and 65535."

#### Scenario: Port zero
- **WHEN** `bastion = { port = 0, allowed_ip_ranges = ["203.0.113.0/24"] }`
- **THEN** the plan fails with the same error message

#### Scenario: No allowed range
- **WHEN** `bastion = { allowed_ip_ranges = [] }`
- **THEN** the plan fails with "bastion.allowed_ip_ranges must hold at least one valid CIDR block."

#### Scenario: Bastion enabled
- **WHEN** `bastion = { port = 2222, allowed_ip_ranges = ["203.0.113.0/24"] }`
- **THEN** the gateways are planned with the bastion on port 2222 limited to that range

### Requirement: SMTP and SSH key refresh
The module SHALL pass `gateway.enable_smtp` (default `false`) to the gateways' `enable_smtp` and `gateway.refresh_ssh_keys` (string, default null) to their `refresh_ssh_keys`.

#### Scenario: SMTP enabled
- **WHEN** `gateway = { enable_smtp = true }`
- **THEN** the gateways are planned with SMTP enabled

#### Scenario: Refresh trigger changed
- **WHEN** `gateway.refresh_ssh_keys` changes from `"1"` to `"2"`
- **THEN** the gateways are planned with the new `refresh_ssh_keys` value

### Requirement: Gateway attachments through IPAM
For every pair of a private network key and a gateway zone, the module SHALL create one IPv4 `scaleway_ipam_ip` sourced from that network and one `scaleway_vpc_gateway_network` connecting the gateway of that zone to that network, with masquerade from `gateway.enable_masquerade` (default `true`) and a default route pushed through the IPAM IP. Both are keyed `<network>-<zone>`.

#### Scenario: Two networks, two zones
- **WHEN** networks `web` and `app` and zones `fr-par-1` and `fr-par-2`
- **THEN** `gateway_network_ids`, `ipam_ip_ids` and `ipam_ip_addresses` each have four entries such as `web-fr-par-1`

#### Scenario: Masquerade disabled
- **WHEN** `gateway = { enable_masquerade = false }`
- **THEN** the gateway networks are planned with masquerade disabled

#### Scenario: Gateway disabled
- **WHEN** `gateway = null`
- **THEN** no IPAM IP and no gateway network is planned

## ADDED Requirements

### Requirement: Port forwarding
The module SHALL create one `scaleway_vpc_public_gateway_pat_rule` per key of `gateway.pat_rules` (map of objects with `zone`, `public_port`, `private_ip`, `private_port` and `protocol`, default `both`), on the gateway of that zone. Ports MUST be 1-65535, `protocol` one of `both`, `tcp` or `udp`, `zone` a zone of `zones`, and two rules of one zone MUST NOT share a `public_port`. `pat_rule_ids` maps each key to the rule ID.

#### Scenario: Rule planned
- **WHEN** `pat_rules = { ssh = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 22 } }`
- **THEN** one rule is planned on the `fr-par-1` gateway with protocol `both`

#### Scenario: Invalid protocol
- **WHEN** a rule has `protocol = "icmp"`
- **THEN** the plan fails with "pat_rules protocol must be 'both', 'tcp' or 'udp', and ports must be between 1 and 65535."

#### Scenario: Port out of range
- **WHEN** a rule has `public_port = 0`
- **THEN** the plan fails with the same error message

#### Scenario: Duplicate public port
- **WHEN** two rules of `fr-par-1` use `public_port = 2222`
- **THEN** the plan fails with "pat_rules must not reuse a public_port within a zone."

#### Scenario: Unknown zone
- **WHEN** a rule has `zone = "nl-ams-1"` and `zones = ["fr-par-1"]`
- **THEN** the plan fails with the zone error message of the flexible IP requirement

#### Scenario: Gateway disabled
- **WHEN** `gateway = null`
- **THEN** no rule is planned and `pat_rule_ids` is empty

## REMOVED Requirements

### Requirement: Flexible IP precedence warning
**Reason**: reserving and attaching an existing IP are no longer two competing inputs; `gateway.flexible_ip_ids` decides per zone, so no warning is needed.
**Migration**: replace `gateway_reserve_flexible_ip = false` plus `gateway_existing_flexible_ip_id = X` by `gateway = { flexible_ip_ids = { "<zone>" = X } }`.
