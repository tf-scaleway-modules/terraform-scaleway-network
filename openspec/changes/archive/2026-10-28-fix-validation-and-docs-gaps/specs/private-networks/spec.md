## MODIFIED Requirements

### Requirement: Network outputs
The module SHALL expose `network_private_network_ids`, `network_ipv4_cidrs` and `network_ipv6_cidrs`, each a map keyed by the `network_private_networks` key. `network_ipv4_cidrs` SHALL hold the first IPv4 subnet of the network or null. `network_ipv6_cidrs` SHALL hold the list of IPv6 subnets of the network, empty when it has none.

#### Scenario: Outputs keyed by network
- **WHEN** networks `web` and `app` exist
- **THEN** each of the three outputs has the keys `web` and `app`

#### Scenario: Network without IPv6 subnet
- **WHEN** a network has no IPv6 subnet
- **THEN** its entry in `network_ipv6_cidrs` is an empty list and the plan does not fail
