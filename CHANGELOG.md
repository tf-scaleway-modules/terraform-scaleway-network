# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-12-14
- Updates Scaleway provider and Terraform versions

Updates the Scaleway provider version to `~> 2.64` and requires Terraform version `>= 1.10.7`.
Adds a data source to retrieve the Scaleway project.
Removes the `vpc_project_id` input variable, and adds `organization_id` and `project_name`
input variables, making them mandatory.
- Initializes Scaleway VPC Terraform module

