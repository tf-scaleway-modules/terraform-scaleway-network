# vpc Specification

## Purpose
The VPC resource: region, tags, transitivity and the zones-belong-to-region validation.

## Requirements

### Requirement: VPC resource
The module SHALL create exactly one `scaleway_vpc` named `name` in the project, in `region` (null by default, which uses the provider region), tagged with `tags` (default `[]`). It SHALL expose its ID as `vpc_id`. `name` MUST be a non-empty string.

#### Scenario: Default region
- **WHEN** `region` is null
- **THEN** the VPC is created in the provider's configured region

#### Scenario: Explicit region and tags
- **WHEN** `region = "fr-par"` and `tags = ["prod"]`
- **THEN** the VPC is planned in `fr-par` with the tag `prod`

#### Scenario: Empty name
- **WHEN** `name = ""`
- **THEN** the plan fails with "name must not be empty."

### Requirement: Zones belong to the region
The `zones` input (list of strings, default `[]`) SHALL be rejected at plan time when it holds an empty string, when `region` is given and a zone does not start with `region`, or when no region is given and the zones do not all share one region prefix (the zone name without its last two characters). An empty list is always accepted.

#### Scenario: Zone outside the region
- **WHEN** `region = "fr-par"` and `zones = ["nl-ams-1"]`
- **THEN** the plan fails with "When both region and zones are specified, all zones must belong to the specified region..."

#### Scenario: Mixed regions without a region
- **WHEN** `region` is null and `zones = ["fr-par-1", "nl-ams-1"]`
- **THEN** the plan fails with the same error message

#### Scenario: Zones in one region without region
- **WHEN** `region` is null and `zones = ["fr-par-1", "fr-par-2"]`
- **THEN** the plan succeeds

#### Scenario: Empty zone string
- **WHEN** `zones = [""]`
- **THEN** the plan fails with "zones must not contain empty strings."

#### Scenario: Zones in the region
- **WHEN** `region = "fr-par"` and `zones = ["fr-par-1", "fr-par-2"]`
- **THEN** the validation passes

#### Scenario: Empty zones
- **WHEN** `zones = []`, with or without `region`
- **THEN** the plan succeeds

### Requirement: Transitivity
The module SHALL pass `enable_transitivity` (bool, default `false`) to the VPC's `enable_transitivity`. It SHALL NOT send `enable_routing` or `enable_custom_routes_propagation`, which the provider always enables.

#### Scenario: Defaults
- **WHEN** `enable_transitivity` is not set
- **THEN** transitivity is disabled, an existing VPC shows no change and a second plan after apply is empty

#### Scenario: Transitivity enabled
- **WHEN** `enable_transitivity = true`
- **THEN** the VPC is planned with `enable_transitivity = true`
