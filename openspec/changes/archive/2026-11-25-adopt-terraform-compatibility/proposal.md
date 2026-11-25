## Why

The `terraform` standards store v2.1.0 sets the core floor to `>= 1.11.0` for every module, read by both OpenTofu and Terraform (`terraform-providers`: Version constraints, scenario "Core floor below the organisation floor"), and requires CI and the toolchain to validate the module with both CLIs (`terraform-repo-gitlab-ci`, `terraform-repo-mise`). This module declares `>= 1.10.7` and validates with OpenTofu only.

## What Changes

- **BREAKING**: `required_version` goes from `>= 1.10.7` to `>= 1.11.0` in `versions.tf`, `examples/minimal/versions.tf` and `examples/complete/versions.tf`. Upgrade note: consumers need OpenTofu or Terraform >= 1.11.0.
- `openspec/config.yaml`: `terraform` store `ref` goes from `v1.2.6` to `v2.1.0`; the context line "required_version >= 1.10.7" follows.
- `mise.toml`: `opentofu` pinned to `1.13.10` (was `1.11`), `terraform = '1.17.2'` added.
- `.gitlab/release.yml`: `validate:opentofu` image becomes `ghcr.io/opentofu/opentofu:1.13.10`; new `validate:terraform` job (`hashicorp/terraform:1.17.2`) validates the root and every example; `create:release` needs it.
- `.pre-commit-config.yaml`: every Terraform hook gets `--hook-config=--tf-path=tofu` (none has it today), per `terraform-repo-precommit` "Terraform hooks run tofu".
- `.github/workflows/ci.yml` and `release.yml`: `tofu_version` goes from `1.11.0` to `1.13.10`, the `mise.toml` pin; no new job.
- Docs outside the terraform-docs markers: README states OpenTofu >= 1.11.0 and Terraform >= 1.11.0 and carries the upgrade note, the Terraform badge is fixed; `AGENTS.md` Commands line adds `terraform init -backend=false && terraform validate` and names both tools.

No input, output, resource, default or state change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `module-contract`: requirement "Supported tooling and provider" raises the core floor from 1.10.7 to 1.11.0, for both OpenTofu and Terraform.

## Impact

- Release level: **major** (`terraform-versioning`: raised `required_version`). Consumers on OpenTofu or Terraform 1.10.x cannot init the new tag until they upgrade to >= 1.11.0.
- Inputs/outputs: none change type, default or meaning. Nothing new lands in state.
- Files: `versions.tf`, `examples/*/versions.tf`, `mise.toml`, `.gitlab/release.yml`, `.pre-commit-config.yaml`, `.github/workflows/*.yml`, `openspec/config.yaml`, `README.md` (outside the markers), `AGENTS.md`, `openspec/specs/module-contract/spec.md` (at archive).
- Standards cited: `terraform-providers`, `terraform-module-structure`, `terraform-repo-gitlab-ci`, `terraform-repo-mise`, `terraform-repo-precommit`, `terraform-versioning`.
