## MODIFIED Requirements

### Requirement: Supported tooling and provider
The module SHALL declare `required_version = ">= 1.11.0"` in `versions.tf`, one constraint read by both OpenTofu and Terraform, and SHALL pin `scaleway/scaleway ~> 2.89` in `versions.tf`.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.89

#### Scenario: Version below the floor
- **WHEN** the module is initialised with OpenTofu or Terraform 1.10.7
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Both tools validate
- **WHEN** `tofu validate` and `terraform validate` run on the module root and on each example
- **THEN** both succeed
