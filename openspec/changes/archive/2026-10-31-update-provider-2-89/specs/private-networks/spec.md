## MODIFIED Requirements

### Requirement: Private networks from a map
The module SHALL create one `scaleway_vpc_private_network` per key of `network_private_networks` (map of objects with optional `name`, `ipv4_subnet`, `ipv6_subnet`, `tags` and `enable_default_route_propagation`, default one entry keyed `default`), attached to the VPC, in the project and in `vpc_region`. Each network's tags SHALL be `vpc_tags` followed by the entry's `tags` (default `[]`). `enable_default_route_propagation` (bool, default `null`) SHALL be passed to the network only when it is not null, so that null keeps the provider and API default and plans no change on an existing network.

#### Scenario: Default input
- **WHEN** `network_private_networks` is not set
- **THEN** one private network keyed `default` is planned with an auto-generated name and auto-assigned subnets

#### Scenario: Two networks
- **WHEN** `network_private_networks = { web = { name = "web-network", tags = ["web"] }, app = {} }` and `vpc_tags = ["prod"]`
- **THEN** two networks keyed `web` and `app` are planned and `web` carries the tags `prod` and `web`

#### Scenario: Empty map
- **WHEN** `network_private_networks = {}`
- **THEN** no private network is planned and the network outputs are empty maps

#### Scenario: Default route propagation set
- **WHEN** a network sets `enable_default_route_propagation = true`
- **THEN** that network is planned with default route propagation enabled and the other networks are unaffected

#### Scenario: Default route propagation unset
- **WHEN** a network does not set `enable_default_route_propagation`
- **THEN** the argument is not set on the network and an existing network shows no change
