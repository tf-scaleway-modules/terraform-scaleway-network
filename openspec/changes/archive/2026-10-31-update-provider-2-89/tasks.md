## 1. VPC routing flags deprecation

- [x] 1.1 `variables.tf`: set `vpc_enable_routing` and `vpc_enable_custom_routes` to `default = null`, prefix each description with "DEPRECATED:" (ignored by the provider, cannot disable the feature, removed in the next major version); keep `type = bool`. Verify: `tofu validate` passes and `tflint --recursive` reports no `terraform_documented_variables` / `terraform_typed_variables` finding.
- [x] 1.2 `main.tf`: update the VPC section comments (drop the "Routing cannot be disabled" warning wording that implies the module controls it); keep both arguments wired to the variables; add `check "vpc_deprecated_routing_flags"` with two `assert`s (`var.vpc_enable_routing == null`, `var.vpc_enable_custom_routes == null`) and messages naming the input and the next-major removal. Verify: the new tests in 1.3 pass.
- [x] 1.3 `tests/main.tftest.hcl` (`mock_provider "scaleway"`, `command = plan`): add runs `vpc_flags_default_no_warning` (no flag set: no warning, `scaleway_vpc.this` has no `enable_routing` / `enable_custom_routes_propagation` set), `vpc_routing_flag_warns` (`vpc_enable_routing = true`, `expect_failures = [check.vpc_deprecated_routing_flags]`) and `vpc_custom_routes_flag_warns` (`vpc_enable_custom_routes = true`, same check). Verify: `tofu test` passes the three runs.

## 2. Private network default route propagation

- [x] 2.1 `variables.tf`: add `enable_default_route_propagation = optional(bool)` to the `network_private_networks` object type (comment: null keeps the provider default) and `enable_default_route_propagation = null` in the default entry; `main.tf`: set `enable_default_route_propagation = each.value.enable_default_route_propagation` on `scaleway_vpc_private_network.this`. Verify: `tofu validate` passes and a plan with the default input still plans one network.
- [x] 2.2 `tests/main.tftest.hcl`: add runs `network_default_route_propagation_set` (network `web` true, `app` unset: `web` planned with `true`, `app` null) and `network_default_route_propagation_unset` (default input: attribute null). There is no new `validation`, hence no rejected-input run. Verify: `tofu test` passes both runs.

## 3. Example and docs

- [x] 3.1 `examples/complete/main.tf`: remove `vpc_enable_routing` and `vpc_enable_custom_routes`; set `enable_default_route_propagation = true` on the `app` network. Check `examples/minimal` does not set the deprecated inputs. Verify: `tofu init -backend=false && tofu validate` in `examples/complete` and `examples/minimal`.
- [x] 3.2 `README.md`: add a short "Upgrade notes" entry (remove the two deprecated inputs from module calls, removed in the next major; no state migration) outside the `BEGIN_TF_DOCS` / `END_TF_DOCS` block. Verify: the block is regenerated only by terraform-docs in 4.2.

## 4. Verify

- [x] 4.1 `tofu fmt -recursive`, then `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`. Verify: all four exit 0; report output as-is.
- [x] 4.2 Move any local `.terraform.lock.hcl` aside (rename it, do not commit it) before `pre-commit run -a` and before pushing: terraform-docs writes the locked provider version (2.89.0) instead of the `~> 2.86` constraint into the README when the lock file is present. Then run `pre-commit run -a`; restore the lock file afterwards. Verify: the README provider row reads `~> 2.86`; the hooks pass.
- [x] 4.3 `mise run spec-validate` and `openspec validate update-provider-2-89 --strict`. Verify: both pass.
- [x] 4.4 Commit subject, which reads as its CHANGELOG line (git-cliff; never edit CHANGELOG.md): "Deprecate VPC routing flags no longer accepted by the provider and add private network default route propagation". Body: upgrade note from 3.2 (remove `vpc_enable_routing` and `vpc_enable_custom_routes` from module calls, no state migration). Semver: minor; `versions.tf` is not changed. Verify: `git log -1 --format=%s` shows the subject.

## Workflow follow-up

- Release verification (needs a real Scaleway project, not run by the unit suite and never without the user's request): apply `examples/minimal` and `examples/complete`, confirm the VPC reads back `enable_routing = true` and `enable_custom_routes_propagation = true`, and that the second plan is empty (design.md, Risks).
- Archive the change after the commit lands and the README block was regenerated; summarize that the `vpc` and `private-networks` main specs changed and that no requirement was removed.
