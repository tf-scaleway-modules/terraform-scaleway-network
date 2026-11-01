# private-networks Specification

## Purpose
Private networks keyed by name with optional subnets and tags, and the network outputs.

## Requirements

### Requirement: Private networks from a map
The module SHALL create one `scaleway_vpc_private_network` per key of `private_networks` (map of objects with optional `name`, `ipv4_subnet`, `ipv6_subnet`, `tags`, `enable_default_route_propagation`; default: one `default` entry), attached to the VPC, in the project and `region`. The name SHALL be the entry's `name`, else `<name>-<key>`. Tags SHALL be the distinct union of `tags` and the entry's `tags`. `enable_default_route_propagation` (default `null`) is sent only when not null.

#### Scenario: Default input
- **WHEN** `private_networks` is not set and `name = "core"`
- **THEN** one private network keyed `default` is planned with the name `core-default` and auto-assigned subnets

#### Scenario: Two networks
- **WHEN** `private_networks = { web = { name = "web-network", tags = ["web"] }, app = {} }` and `tags = ["prod"]`
- **THEN** `web` is named `web-network` with the tags `prod` and `web`, and `app` is named `<name>-app` with the tag `prod`

#### Scenario: Duplicate tag
- **WHEN** `tags = ["prod"]` and a network sets `tags = ["prod", "web"]`
- **THEN** that network carries the tags `prod` and `web` once each

#### Scenario: Empty map
- **WHEN** `private_networks = {}`
- **THEN** no private network is planned and the network outputs are empty maps

#### Scenario: Default route propagation set
- **WHEN** a network sets `enable_default_route_propagation = true`
- **THEN** that network is planned with default route propagation enabled and the other networks are unaffected

#### Scenario: Default route propagation unset
- **WHEN** a network does not set `enable_default_route_propagation`
- **THEN** the argument is not set on the network and an existing network shows no change

### Requirement: Optional subnets
A network SHALL declare an IPv4 subnet only when its `ipv4_subnet` is not null, and an IPv6 subnet only when its `ipv6_subnet` is not null; otherwise Scaleway assigns the subnets. A given subnet MUST be a valid CIDR of its family.

#### Scenario: Fixed IPv4 subnet
- **WHEN** a network sets `ipv4_subnet = "10.0.1.0/24"`
- **THEN** the network is planned with that IPv4 subnet

#### Scenario: Fixed IPv6 subnet
- **WHEN** a network sets `ipv6_subnet = "2001:db8::/64"`
- **THEN** the network is planned with that IPv6 subnet

#### Scenario: No subnet given
- **WHEN** both subnet fields are null
- **THEN** no subnet block is planned and Scaleway assigns the subnets

#### Scenario: Invalid CIDR
- **WHEN** a network sets `ipv4_subnet = "10.0.1.0/33"`
- **THEN** the plan fails with "ipv4_subnet and ipv6_subnet must be valid CIDR blocks."

### Requirement: Network outputs
The module SHALL expose `private_network_ids`, `private_network_ipv4_cidrs` and `private_network_ipv6_cidrs`, each a map keyed by the `private_networks` key. `private_network_ipv4_cidrs` SHALL hold the first IPv4 subnet of the network or null. `private_network_ipv6_cidrs` SHALL hold the list of IPv6 subnets of the network, empty when it has none.

#### Scenario: Outputs keyed by network
- **WHEN** networks `web` and `app` exist
- **THEN** each of the three outputs has the keys `web` and `app`

#### Scenario: Network without IPv6 subnet
- **WHEN** a network has no IPv6 subnet
- **THEN** its entry in `private_network_ipv6_cidrs` is an empty list and the plan does not fail
