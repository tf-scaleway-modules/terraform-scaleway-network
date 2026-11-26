# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-12-25
- Updates Scaleway provider and Terraform versions

Updates the Scaleway provider and requires a minimum Terraform version.

Adds a data source to retrieve the Scaleway project. Removes the `vpc_project_id` input variable, and adds `organization_id` and `project_name` input variables, making them mandatory, to align with current Scaleway best practices.
## [1.0.0] - 2025-12-14
- Require OpenTofu or Terraform 1.11.0 and validate with both

BREAKING: required_version is raised from >= 1.10.7 to >= 1.11.0.
Upgrade note: consumers need OpenTofu or Terraform >= 1.11.0.

Pin opentofu 1.13.10 and terraform 1.17.2, add the validate:terraform CI
job, run the Terraform pre-commit hooks with tofu, bump the GitHub
workflows to tofu 1.13.10 and adopt the terraform standards store v2.1.0.
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry
- Collapse inputs into objects and add VPC routes, port forwarding and a dual-stack ACL

BREAKING: v2.0.0; provider ~> 2.89. The 24 flat inputs become 10
(project_id, region, zones, name, tags, enable_transitivity,
private_networks, gateway, access_control_list, routes).

- organization_id/project_name are replaced by project_id.
- vpc_* and network_* inputs are renamed; the deprecated
  vpc_enable_routing and vpc_enable_custom_routes are removed.
- enable_gateway, gateway_*, enable_bastion and bastion_* merge into the
  nullable gateway object; gateway.flexible_ip_ids (zone to ID) replaces
  the reserve/existing pair; bastion allowed_ip_ranges is required.
- access_control_list has ipv4/ipv6 families and no default HTTP rule;
  scaleway_vpc_acl.this[0] moves to this["ipv4"] (IPv6-only ACLs need a
  root moved block or state mv).
- Gateways are renamed <name>-<zone> and unnamed private networks
  <name>-<key> (in place).
- Outputs become private_network_ids, private_network_ipv4_cidrs,
  private_network_ipv6_cidrs and access_control_list_ids; new route_ids
  and pat_rule_ids.
- New routes (scaleway_vpc_route), gateway.pat_rules, gateway types
  VPC-GW-L/XL; the ACL is now placed in region.

See "Upgrading from v1 to v2" in the README.
- Deprecate VPC routing flags ignored by the provider and add private network default route propagation

Upgrade note: remove vpc_enable_routing and vpc_enable_custom_routes from
module calls; the provider ignores them and they are removed in the next
major version. No state migration; a plain upgrade plans no change.
- Fix empty IPv6 output, validate ACL rules and clarify flexible IP and gateway name docs

- network_ipv6_cidrs no longer errors for a network without an IPv6 subnet.
- access_control_list_rules rejects unknown protocol and action values when the ACL is enabled.
- A check warns when gateway_existing_flexible_ip_id is set while gateway_reserve_flexible_ip is true.
- Correct the vpc_name, gateway_existing_flexible_ip_id and access_control_list_rules descriptions and the README release badge.
- Cover the vpc_zones validation with unit tests.
No upgrade action needed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Key the pre-commit cache on mise.toml and .pre-commit-config.yaml

The cache was keyed on the branch, so a branch kept tools installed by the previous mise, which the new one no longer puts on PATH (tofu not found). Keying it on the files that define the toolchain, as in scaleway-compute and scaleway-storage, starts a fresh cache whenever the toolchain changes and shares it across branches and tags.
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Adopt OpenSpec and publish the baseline specs

Planning adopts OpenSpec, aligned with the other leminnov Terraform
modules: the engineering standards come from the quality, repository and
terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- feat: add vpc_enable_transitivity and upgrade scaleway provider to ~> 2.86

- Add vpc_enable_transitivity (packets from peered VPCs can transit).
- Bump the scaleway provider constraint to ~> 2.86 (module and examples).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Adds organization and project to examples

Adds organization ID and project name to the example configurations.

Adds mise tasks for cleaning up terraform cache, lock files and state files.
These tasks helps to remove stale files and ensure a clean environment
for testing and development.
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

