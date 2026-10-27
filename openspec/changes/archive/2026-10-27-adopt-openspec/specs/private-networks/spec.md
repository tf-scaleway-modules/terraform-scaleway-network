## ADDED Requirements

### Requirement: Private networks from a map
The module SHALL create one `scaleway_vpc_private_network` per key of `network_private_networks` (map of objects with optional `name`, `ipv4_subnet`, `ipv6_subnet` and `tags`, default one entry keyed `default`), attached to the VPC, in the project and in `vpc_region`. Each network's tags SHALL be `vpc_tags` followed by the entry's `tags` (default `[]`).

#### Scenario: Default input
- **WHEN** `network_private_networks` is not set
- **THEN** one private network keyed `default` is planned with an auto-generated name and auto-assigned subnets

#### Scenario: Two networks
- **WHEN** `network_private_networks = { web = { name = "web-network", tags = ["web"] }, app = {} }` and `vpc_tags = ["prod"]`
- **THEN** two networks keyed `web` and `app` are planned and `web` carries the tags `prod` and `web`

#### Scenario: Empty map
- **WHEN** `network_private_networks = {}`
- **THEN** no private network is planned and the network outputs are empty maps

### Requirement: Optional subnets
A network SHALL declare an IPv4 subnet only when its `ipv4_subnet` is not null, and an IPv6 subnet only when its `ipv6_subnet` is not null; otherwise Scaleway assigns the subnets.

#### Scenario: Fixed IPv4 subnet
- **WHEN** a network sets `ipv4_subnet = "10.0.1.0/24"`
- **THEN** the network is planned with that IPv4 subnet

#### Scenario: Fixed IPv6 subnet
- **WHEN** a network sets `ipv6_subnet = "2001:db8::/64"`
- **THEN** the network is planned with that IPv6 subnet

#### Scenario: No subnet given
- **WHEN** both subnet fields are null
- **THEN** no subnet block is planned and Scaleway assigns the subnets

### Requirement: Network outputs
The module SHALL expose `network_private_network_ids`, `network_ipv4_cidrs` and `network_ipv6_cidrs`, each a map keyed by the `network_private_networks` key. `network_ipv4_cidrs` SHALL hold the first IPv4 subnet of the network or null.

#### Scenario: Outputs keyed by network
- **WHEN** networks `web` and `app` exist
- **THEN** each of the three outputs has the keys `web` and `app`
