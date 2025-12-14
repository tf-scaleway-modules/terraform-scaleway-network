# ==============================================================================
# Data Sources
# ==============================================================================
# This file contains data source lookups for external resources and configuration.
# Data sources allow Terraform to reference existing infrastructure that is not
# managed by this module.

# ------------------------------------------------------------------------------
# Scaleway Account Project Lookup
# ------------------------------------------------------------------------------
# Retrieves information about a Scaleway project within an organization.
# This data source is used to:
# - Resolve the project ID from the project name
# - Ensure resources are created in the correct organizational context
# - Validate that the specified project exists before creating resources
#
# The retrieved project ID is used throughout the module to associate all
# created resources (VPC, networks, gateways, etc.) with the specified project.
#
# Required Variables:
# - var.project_name: Name of the Scaleway project
# - var.organization_id: ID of the Scaleway organization containing the project
#
# Output:
# - project.id: The project identifier used for resource association
data "scaleway_account_project" "project" {
  name            = var.project_name
  organization_id = var.organization_id
}
