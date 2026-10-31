## Context

See proposal.md. `versions.tf` pins `scaleway/scaleway ~> 2.86`, which already resolves to 2.89.0. Observed in the provider source (v2.86.0 and v2.89.0, `internal/services/vpc`): `scaleway_vpc.enable_routing` and `enable_custom_routes_propagation` are `Optional + Computed` in both tags; 2.88.0 only adds `Deprecated`. The VPC `CustomizeDiff` rejects turning either off on an existing VPC. `scaleway_vpc_private_network.enable_default_route_propagation` is `Optional + Computed` in both tags and is read back from the API.

## Goals / Non-Goals

**Goals**
- No deprecated provider argument sent by default; no consumer change needed to upgrade.
- Expose the private network routing attribute with the same `null` = server default convention as the other optional attributes.

**Non-Goals**
- Removing `vpc_enable_routing` / `vpc_enable_custom_routes` (next major, with the provider's removal).
- Raising the provider floor, adding resources, outputs or other new inputs (see the proposal's deferred list).

## Decisions

### 1. Deprecate the two VPC flags instead of removing them
- `scaleway_vpc.this`: `enable_routing = var.vpc_enable_routing` and `enable_custom_routes_propagation = var.vpc_enable_custom_routes` stay in the resource, but both variables default to `null`. A `null` argument is omitted from the provider config; because the attributes are Optional+Computed, the state value (`true`) is kept and the plan is empty. Introduced as deprecated in provider 2.88.0; Optional+Computed since before 2.86.0.
- Each variable keeps `type = bool`; its description starts with "DEPRECATED: ..." and says it is ignored by the provider on new VPCs, cannot disable the feature, and is removed in the next major (`terraform-variables` Declaration shape, `terraform-versioning` Breaking change checklist: keep for one version, deprecated in the description). Rationale for keeping a pass-through when set (rather than ignoring the value): a legacy VPC created before routing was always on can still be moved to `true` through the provider update path, and removing that path silently would be a behaviour change.
- `check "vpc_deprecated_routing_flags"` in `main.tf` with two `assert`s: `var.vpc_enable_routing == null` and `var.vpc_enable_custom_routes == null`, each with an `error_message` naming the input, the reason and "removed in the next major version". A `check` warns and never fails (`terraform-security` Guardrails: legal but unwanted configuration; a `validation` would break callers that still set `true`).
- Alternative rejected: delete both inputs now. Major bump and breaks every caller that sets them (the module's own example does).
- Alternative rejected: keep default `true`. Every plan would keep sending deprecated arguments and provider warnings would reach consumers who never set them.
- Semver detail: the default `true` → `null` is a changed default, which `terraform-versioning` classes as major only when it alters resources. Here no resource is altered: existing state reads `true` and stays; new VPCs are always routed by the provider and API (the provider docs: "always enabled on newly created VPCs"). The change is therefore **minor**. This reading rests on that provider statement, which the release verification below confirms against a real project.

### 2. `enable_default_route_propagation` on private networks
- `network_private_networks` object type gains `enable_default_route_propagation = optional(bool)` (null default). The resource sets `enable_default_route_propagation = each.value.enable_default_route_propagation`. Provider argument present in 2.86.0 (and in the 2.86.0 docs), so no floor change.
- No invented default (`terraform-variables` "Optional attribute with an invented default"): null leaves the argument out, the attribute is Computed, the plan stays empty for existing networks. New networks get the API default. In-place update only when a caller sets it (the provider updates it without replacement).
- The gateway attachment keeps `push_default_route = true` in `ipam_config`; the two settings are independent and no coupling is added.
- Adding an optional attribute with a `null` default to a map input is a minor change (`terraform-versioning` scenario "Optional input added").

### 3. Provider floor stays `~> 2.86`
Per the decided need-driven policy and `terraform-providers` "Raised floor": a floor raise is only taken for an argument introduced after 2.86.0. Neither adopted item qualifies, so `versions.tf` is untouched and no major bump is needed. The unit tests run against the resolved provider (2.89.0), consumers on a locked 2.86.x–2.87.x provider see the same behaviour (the arguments exist there; only the deprecation warning is new in 2.88.0).

## Risks / Trade-offs

- [New VPC created with the flags unset: the provider sends `EnableRouting=false` in the create request while claiming routing is always on] → release verification: apply `examples/minimal` in a sandbox project and confirm `enable_routing` and `enable_custom_routes_propagation` read back `true` and the second plan is empty. If routing were off, the default would go back to `true` (and the deprecation would move to the next release).
- [Callers that set the deprecated inputs keep seeing the provider's own deprecation warning in addition to the module check] → accepted; the module warning names the module input to remove.
- [A caller sets a legacy VPC to `false`] → unchanged behaviour: the provider's `CustomizeDiff` refuses to disable the feature; the check also warns.
- [`enable_default_route_propagation = true` changes routing on a live network] → in-place update, applies only to networks where the caller sets it; documented in the variable comment and the README upgrade note.

## Migration Plan

- State: no `moved` blocks, no `state mv`, no replacement. VPC and private networks update nothing on a plain upgrade (empty plan). Setting `enable_default_route_propagation` on a network is an in-place update.
- Upgrade note (README and commit body): remove `vpc_enable_routing` and `vpc_enable_custom_routes` from module calls; they are ignored by the provider and will be removed in the next major version.
- Rollback: pin the previous git tag; state is untouched by this change.

## Implementation notes

- Unit tests cannot assert `null` on `scaleway_vpc.this.enable_routing`, `enable_custom_routes_propagation` or the private network `enable_default_route_propagation` in a plan: the attributes are Optional+Computed, hence unknown. The "unset" runs assert the absence of the deprecation warning and read the input through `try(var.network_private_networks[...].enable_default_route_propagation, null)` (Terraform drops null optional attributes from the object).
