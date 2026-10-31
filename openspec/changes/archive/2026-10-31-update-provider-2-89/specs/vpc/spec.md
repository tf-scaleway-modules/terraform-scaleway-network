## MODIFIED Requirements

### Requirement: Routing flags
The module SHALL pass `vpc_enable_transitivity` (default `false`) to the VPC argument `enable_transitivity`. The inputs `vpc_enable_routing` and `vpc_enable_custom_routes` (bool, default `null`) are DEPRECATED, because the provider always enables routing and custom route propagation on VPCs and cannot disable them; their descriptions SHALL say so and that they will be removed in the next major version. The module SHALL pass them to `enable_routing` and `enable_custom_routes_propagation` only when they are not null, so the default plan sends neither argument and changes no existing VPC. A `check` SHALL warn, without failing the plan, when either input is set to any value.

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
