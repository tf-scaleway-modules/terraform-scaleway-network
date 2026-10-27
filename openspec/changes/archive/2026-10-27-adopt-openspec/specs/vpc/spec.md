## ADDED Requirements

### Requirement: VPC resource
The module SHALL create exactly one `scaleway_vpc` named `vpc_name` in the project, in region `vpc_region` (null by default, which uses the provider region), tagged with `vpc_tags` (default `[]`). It SHALL expose its ID as `vpc_id`.

#### Scenario: Default region
- **WHEN** `vpc_region` is null
- **THEN** the VPC is created in the provider's configured region

#### Scenario: Explicit region and tags
- **WHEN** `vpc_region = "fr-par"` and `vpc_tags = ["prod"]`
- **THEN** the VPC is planned in `fr-par` with the tag `prod`

### Requirement: Routing flags
The module SHALL pass `vpc_enable_routing` (default `true`), `vpc_enable_custom_routes` (default `true`) and `vpc_enable_transitivity` (default `false`) to the VPC arguments `enable_routing`, `enable_custom_routes_propagation` and `enable_transitivity`.

#### Scenario: Defaults
- **WHEN** none of the three flags is set
- **THEN** the VPC has routing and custom route propagation enabled and transitivity disabled

#### Scenario: Transitivity enabled
- **WHEN** `vpc_enable_transitivity = true`
- **THEN** the VPC is planned with `enable_transitivity = true`

### Requirement: Zones belong to the region
The `vpc_zones` input (list of strings, default `[]`) SHALL be rejected at plan time when a region is given and a zone does not start with `vpc_region`, or when no region is given and the zones do not all share one region prefix (the zone name without its last two characters). An empty list is always accepted.

#### Scenario: Zone outside the region
- **WHEN** `vpc_region = "fr-par"` and `vpc_zones = ["nl-ams-1"]`
- **THEN** the plan fails with "When both region and zones are specified, all zones must belong to the specified region..."

#### Scenario: Mixed regions without a region
- **WHEN** `vpc_region` is null and `vpc_zones = ["fr-par-1", "nl-ams-1"]`
- **THEN** the plan fails with the same error message

#### Scenario: Zones in the region
- **WHEN** `vpc_region = "fr-par"` and `vpc_zones = ["fr-par-1", "fr-par-2"]`
- **THEN** the validation passes
