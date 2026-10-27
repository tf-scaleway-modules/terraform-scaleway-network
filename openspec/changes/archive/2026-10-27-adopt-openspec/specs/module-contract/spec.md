## ADDED Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.10.7"` and SHALL pin `scaleway/scaleway ~> 2.86` in `versions.tf`.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.86

#### Scenario: Version below the floor
- **WHEN** the module is initialised with OpenTofu or Terraform 1.10.6
- **THEN** initialisation fails on the `required_version` constraint

### Requirement: No provider or backend configuration
The module SHALL NOT contain `provider {}` or `backend {}` blocks; the caller configures the Scaleway provider (credentials, default region) and the state backend.

#### Scenario: Provider block inside the module
- **WHEN** a change adds a `provider "scaleway" {}` or `backend` block to a module file
- **THEN** it is moved to the caller or to the example's own configuration, and the module only declares `required_providers`

### Requirement: Project lookup by name
The module SHALL require the string inputs `organization_id`, `project_name` and `vpc_name` (no default) and SHALL resolve the project through the `scaleway_account_project` data source from `project_name` and `organization_id`. Every project-scoped resource it creates SHALL use that project's ID.

#### Scenario: Missing required input
- **WHEN** the module is called without `organization_id`, `project_name` or `vpc_name`
- **THEN** the plan fails because the input is required

#### Scenario: Unknown project
- **WHEN** no project named `project_name` exists in the organization
- **THEN** the plan fails on the data source lookup and no resource is planned

### Requirement: Input surface
The module SHALL expose exactly 24 input variables, each with a `type` and a `description`; only `organization_id`, `project_name` and `vpc_name` are required, every other input has a default. None of the inputs is sensitive.

#### Scenario: Minimal call
- **WHEN** the module is called with only `organization_id`, `project_name` and `vpc_name`
- **THEN** the plan contains the VPC and one private network keyed `default`, and no gateway because `vpc_zones` is empty

### Requirement: Output surface
The module SHALL expose the outputs `vpc_id`, `network_private_network_ids`, `network_ipv4_cidrs`, `network_ipv6_cidrs`, `gateway_ids`, `gateway_flexible_ip_ids`, `gateway_flexible_ip_addresses`, `gateway_network_ids`, `ipam_ip_ids`, `ipam_ip_addresses` and `access_control_list_id`. No output is sensitive.

#### Scenario: Optional blocks disabled
- **WHEN** the gateway and the access control list are disabled
- **THEN** the gateway, flexible IP, gateway network and IPAM maps are empty and `access_control_list_id` is null
