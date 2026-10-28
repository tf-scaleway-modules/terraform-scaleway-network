## MODIFIED Requirements

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
