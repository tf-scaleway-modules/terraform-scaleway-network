# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-12-14
- Updates Scaleway provider and Terraform versions

Updates the Scaleway provider version to `~> 2.64` and requires Terraform version `>= 1.10.7`.
Adds a data source to retrieve the Scaleway project.
Removes the `vpc_project_id` input variable, and adds `organization_id` and `project_name`
input variables, making them mandatory.
- Initializes Scaleway VPC Terraform module

Adds initial files for a Terraform module to manage Scaleway VPC infrastructure, including:

- Core VPC resources: VPC, private networks, public gateways, ACLs, and IPAM
- Configuration files: .cliff.toml, .editorconfig, .gitignore, .gitlab-ci.yml, mise.toml, .pre-commit-config.yaml, .tflint.hcl
- Documentation: README.md, LICENSE
- Example configurations: minimal and complete
- Initial commit

