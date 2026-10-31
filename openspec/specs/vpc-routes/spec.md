# vpc-routes Specification

## Purpose
Custom VPC routes: one `scaleway_vpc_route` per `routes` entry, its next-hop rules and the `route_ids` output.

## Requirements

### Requirement: Custom VPC routes
The module SHALL create one `scaleway_vpc_route` per key of `routes` (map of objects with required `destination`, optional `description` and `tags`, and exactly one next hop: `nexthop_private_network` (a key of `private_networks`), `nexthop_resource_id` or `nexthop_vpc_connector_id`), on the VPC, in `region`. Route tags SHALL be the distinct union of `tags` and the route's `tags`. `routes` defaults to `{}` and `route_ids` SHALL map each key to the route ID.

#### Scenario: No routes by default
- **WHEN** `routes` is not set
- **THEN** no route is planned and `route_ids` is empty

#### Scenario: Route through a module private network
- **WHEN** `routes = { appliance = { destination = "192.168.0.0/16", nexthop_private_network = "app" } }` and `private_networks` has the key `app`
- **THEN** one route is planned to that destination through the private network `app`

#### Scenario: Route through a resource
- **WHEN** a route sets `nexthop_resource_id` and no other next hop
- **THEN** the route is planned with that next hop resource

### Requirement: Route validation
Each route MUST set exactly one next hop, its `destination` MUST be a valid CIDR, and a `nexthop_private_network` MUST be a key of `private_networks`.

#### Scenario: Two next hops
- **WHEN** a route sets `nexthop_resource_id` and `nexthop_vpc_connector_id`
- **THEN** the plan fails with "Each route must set exactly one of nexthop_private_network, nexthop_resource_id or nexthop_vpc_connector_id."

#### Scenario: No next hop
- **WHEN** a route sets none of the three next hops
- **THEN** the plan fails with the same error message

#### Scenario: Invalid destination
- **WHEN** a route has `destination = "10.0.0.0/40"`
- **THEN** the plan fails with "Route destinations must be valid CIDR blocks."

#### Scenario: Unknown private network key
- **WHEN** a route sets `nexthop_private_network = "missing"` and no such key exists in `private_networks`
- **THEN** the plan fails with "nexthop_private_network must be a key of private_networks."
