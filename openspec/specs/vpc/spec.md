# vpc Specification

## Purpose
The VPC resource: region, tags, routing flags and the zones-belong-to-region validation.

## Requirements

### Requirement: VPC resource
The module SHALL create exactly one `scaleway_vpc` named `vpc_name` in the project, in region `vpc_region` (null by default, which uses the provider region), tagged with `vpc_tags` (default `[]`). It SHALL expose its ID as `vpc_id`.

#### Scenario: Default region
- **WHEN** `vpc_region` is null
- **THEN** the VPC is created in the provider's configured region

#### Scenario: Explicit region and tags
- **WHEN** `vpc_region = "fr-par"` and `vpc_tags = ["prod"]`
- **THEN** the VPC is planned in `fr-par` with the tag `prod`

### Requirement: Routing flags
The module SHALL pass `vpc_enable_transitivity` (default `false`) to `enable_transitivity`. `vpc_enable_routing` and `vpc_enable_custom_routes` (bool, default `null`) are DEPRECATED (the provider always enables both); their descriptions SHALL say so and announce removal in the next major. They SHALL be passed to `enable_routing` and `enable_custom_routes_propagation` only when not null, so the default plan changes no VPC. A `check` SHALL warn, without failing the plan, when either is set.

#### Scenario: Defaults
- **WHEN** none of the three flags is set
- **THEN** the VPC is planned without `enable_routing` and `enable_custom_routes_propagation` in the configuration, transitivity is disabled, and a second plan after apply is empty

#### Scenario: Existing VPC upgraded
- **WHEN** a VPC created by an earlier module version (state `enable_routing = true`, `enable_custom_routes_propagation = true`) is planned without the two inputs
- **THEN** the plan shows no change on the VPC

#### Scenario: Transitivity enabled
- **WHEN** `vpc_enable_transitivity = true`
- **THEN** the VPC is planned with `enable_transitivity = true`

#### Scenario: Deprecated routing flag set
- **WHEN** `vpc_enable_routing = true`
- **THEN** the argument is passed to the VPC and the plan warns that `vpc_enable_routing` is deprecated and will be removed

#### Scenario: Deprecated custom routes flag set
- **WHEN** `vpc_enable_custom_routes = true`
- **THEN** the argument is passed to the VPC and the plan warns that `vpc_enable_custom_routes` is deprecated and will be removed

#### Scenario: Deprecated flags unset
- **WHEN** neither `vpc_enable_routing` nor `vpc_enable_custom_routes` is set
- **THEN** the plan emits no deprecation warning

### Requirement: Zones belong to the region
The `vpc_zones` input (list of strings, default `[]`) SHALL be rejected at plan time when a region is given and a zone does not start with `vpc_region`, or when no region is given and the zones do not all share one region prefix (the zone name without its last two characters). An empty list is always accepted. The rule is unchanged and is covered by unit tests.

#### Scenario: Zone outside the region
- **WHEN** `vpc_region = "fr-par"` and `vpc_zones = ["nl-ams-1"]`
- **THEN** the plan fails with "When both region and zones are specified, all zones must belong to the specified region..."

#### Scenario: Mixed regions without a region
- **WHEN** `vpc_region` is null and `vpc_zones = ["fr-par-1", "nl-ams-1"]`
- **THEN** the plan fails with the same error message

#### Scenario: Zones in the region
- **WHEN** `vpc_region = "fr-par"` and `vpc_zones = ["fr-par-1", "fr-par-2"]`
- **THEN** the validation passes

#### Scenario: Zones in one region without region
- **WHEN** `vpc_region` is null and `vpc_zones = ["fr-par-1", "fr-par-2"]`
- **THEN** the plan succeeds

#### Scenario: Empty zones
- **WHEN** `vpc_zones = []`, with or without `vpc_region`
- **THEN** the plan succeeds
