## MODIFIED Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.10.7"` and SHALL pin `scaleway/scaleway ~> 2.89` in `versions.tf`.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.89

#### Scenario: Version below the floor
- **WHEN** the module is initialised with OpenTofu or Terraform 1.10.6
- **THEN** initialisation fails on the `required_version` constraint

### Requirement: Input surface
The module SHALL expose exactly 10 input variables, each with a `type` and a `description`: `project_id`, `region`, `zones`, `name`, `tags`, `enable_transitivity`, `private_networks`, `gateway`, `access_control_list` and `routes`. Only `name` is required. None is sensitive.

#### Scenario: Minimal call
- **WHEN** the module is called with only `name`
- **THEN** the plan contains the VPC and one private network keyed `default`, and no gateway because `zones` is empty

#### Scenario: Missing name
- **WHEN** the module is called without `name`
- **THEN** the plan fails because the input is required

### Requirement: Output surface
The module SHALL expose the outputs `vpc_id`, `private_network_ids`, `private_network_ipv4_cidrs`, `private_network_ipv6_cidrs`, `gateway_ids`, `gateway_flexible_ip_ids`, `gateway_flexible_ip_addresses`, `gateway_network_ids`, `ipam_ip_ids`, `ipam_ip_addresses`, `access_control_list_ids`, `route_ids` and `pat_rule_ids`. No output is sensitive.

#### Scenario: Optional blocks disabled
- **WHEN** the gateway, the access control list and the routes are not configured
- **THEN** every map output except `vpc_id` and the private network maps is empty

## ADDED Requirements

### Requirement: Project selection
The module SHALL take an optional `project_id` (string, default `null`) and pass it to every project-scoped resource; `null` selects the provider's default project. The module SHALL NOT look the project up through a data source. A value that is not a UUID MUST be rejected.

#### Scenario: Default project
- **WHEN** `project_id` is not set
- **THEN** no data source is read and the resources use the provider's default project

#### Scenario: Explicit project
- **WHEN** `project_id = "11111111-1111-1111-1111-111111111111"`
- **THEN** the VPC, private networks, gateways, flexible IPs and IPAM IPs are planned in that project

#### Scenario: Invalid project ID
- **WHEN** `project_id = "default"`
- **THEN** the plan fails with "project_id must be a project UUID or null."

## REMOVED Requirements

### Requirement: Project lookup by name
**Reason**: `organization_id` and `project_name` plus the `scaleway_account_project` data source are replaced by `project_id`.
**Migration**: pass the project UUID as `project_id` (or omit it for the provider default project) and delete `organization_id` and `project_name`.
