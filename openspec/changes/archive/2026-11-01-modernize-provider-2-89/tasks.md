## 1. Provider and project

- [x] 1.1 `versions.tf`, `examples/minimal/versions.tf`, `examples/complete/versions.tf`: `scaleway/scaleway ~> 2.89`; `required_version` stays `>= 1.10.7`
- [x] 1.2 Delete `data.tf`; add `project_id` (string, default null, UUID validation "project_id must be a project UUID or null."); remove `organization_id` and `project_name`; use `var.project_id` on VPC, private network, gateway IP, gateway and IPAM IP
- [x] 1.3 Remove `vpc_enable_routing`, `vpc_enable_custom_routes`, `enable_routing`, `enable_custom_routes_propagation` and `check "vpc_deprecated_routing_flags"`

## 2. Variables and VPC

- [x] 2.1 Rename `vpc_region`/`vpc_zones`/`vpc_name`/`vpc_tags`/`vpc_enable_transitivity` to `region`/`zones`/`name`/`tags`/`enable_transitivity`; `name` validation "name must not be empty."; `zones` validation extended with "zones must not contain empty strings."
- [x] 2.2 `locals.tf`: drop `common_tags` and `compact()`; derive `gateway_zones`, `reserved_ip_zones`, `network_zone_pairs`, `pat_rules` from `var.gateway`
- [x] 2.3 `private_networks` (renamed): name `coalesce(name, "<name>-<key>")`, tags `distinct(concat(var.tags, tags))`, CIDR validation "ipv4_subnet and ipv6_subnet must be valid CIDR blocks."

## 3. Gateway, bastion, flexible IPs, PAT rules

- [x] 3.1 Replace `enable_gateway`, `gateway_*`, `enable_bastion`, `bastion_*` by the nullable `gateway` object (design decision 4); remove `check "gateway_flexible_ip"`
- [x] 3.2 Gateway name `<name>-<zone>`; `ip_id` from `flexible_ip_ids` else the reserved IP; reserved IPs only for `reserved_ip_zones`; bastion arguments from `gateway.bastion`
- [x] 3.3 Validations with the exact messages of the specs: type (S/M/L/XL), bastion port, `allowed_ip_ranges` non-empty valid CIDRs, zones of `flexible_ip_ids` keys and `pat_rules[*].zone`, PAT protocol/ports, unique `public_port` per zone
- [x] 3.4 Add `scaleway_vpc_public_gateway_pat_rule.this` (`for_each`, `depends_on` gateway networks); confirm the accepted protocol casing in the 2.89 docs
- [x] 3.5 Gateway network `enable_masquerade = var.gateway.enable_masquerade`; IPAM IP and gateway network keys unchanged

## 4. Access control list and routes

- [x] 4.1 Replace `enable_access_control_list` and `access_control_list_*` by the nullable `access_control_list` object (`ipv4`/`ipv6`, `default_policy`, `rules`); `for_each` over the families, `is_ipv6`, `region = var.region`; no default rule; rule validations (enums, ports 0-65535 and low <= high, CIDRs)
- [x] 4.2 `moved { from = scaleway_vpc_acl.this[0], to = scaleway_vpc_acl.this["ipv4"] }`
- [x] 4.3 Add `routes` and `scaleway_vpc_route.this` (design decision 6) with validations: exactly one next hop, valid destination, known private network key; confirm next-hop combinations against the 2.89 docs

## 5. Outputs

- [x] 5.1 Rename `network_*` outputs to `private_network_*`; `access_control_list_id` to `access_control_list_ids` (map); add `route_ids` and `pat_rule_ids`; keep every description accurate (`gateway_flexible_ip_*` list only module-reserved IPs)

## 6. Unit tests (`tests/main.tftest.hcl`, `mock_provider "scaleway"`)

- [x] 6.1 Drop `override_data` and `organization_id`/`project_name`; add mocks for `scaleway_vpc_public_gateway_pat_rule` and `scaleway_vpc_route`; base `variables { name = "test" }`
- [x] 6.2 Keep and rename the existing runs (minimal plan, zones/region, ACL, IPv6 output, default route propagation); delete the runs for the removed checks and flags
- [x] 6.3 New success runs: `project_id` passed to resources; gateway name `<name>-<zone>`; default private network name; distinct tag merge; `gateway = null`; `flexible_ip_ids` for one of two zones (one reserved IP); bastion enabled; L type; PAT rule planned; ACL IPv4 only, IPv6 only and both; ACL with no rule; each route next-hop kind
- [x] 6.4 A rejected-input run (`expect_failures`) per validation: project_id, empty name, empty zone string, zone outside region, invalid CIDR (subnet), gateway type, bastion port 0 and 70000, empty `allowed_ip_ranges`, `flexible_ip_ids` zone outside `zones`, PAT protocol, PAT port 0, duplicate PAT public port, PAT unknown zone, ACL policy, protocol, action, inverted port range, ACL invalid CIDR, route with two and with no next hops, route invalid destination, route unknown private network key
- [x] 6.5 No `check` blocks remain, so no check run is needed; assert the empty-output case (gateway, ACL and routes unset)

## 7. Examples and documentation

- [x] 7.1 `examples/minimal`: `name`, `region`, `zones`, `private_networks`; no project lookup inputs
- [x] 7.2 `examples/complete`: `project_id` comment, dual-stack ACL with rules, bastion with an explicit range, per-zone `flexible_ip_ids` (fed from an example variable defaulting to `{}`), PAT rule, route through a private network, `tags`; update `outputs.tf` (`access_control_list_ids`, `route_ids`)
- [x] 7.3 README: replace "Upgrade notes" by "Upgrading from v1 to v2": input/output rename table, the consumer edit for every row of the proposal's Breaking table, the in-place renames (gateway, unnamed networks), `moved` for the ACL and the one-time `tofu state mv` for IPv6-only ACLs, removal of the default HTTP rule and bastion default range
- [x] 7.4 Update the compatibility statement (provider `~> 2.89`) if the README states one

## 8. Specs and repository checks

- [x] 8.1 `mise exec -- openspec validate modernize-provider-2-89 --strict` and `mise exec -- openspec validate --all --strict`
- [x] 8.2 `mise exec -- tofu fmt -recursive`
- [x] 8.3 `mise exec -- tofu init -backend=false && mise exec -- tofu validate`; delete the produced `.terraform.lock.hcl` afterwards
- [x] 8.4 `mise exec -- tflint --recursive`
- [x] 8.5 `mise exec -- tofu test`
- [x] 8.6 Move any local `.terraform.lock.hcl` aside, then `mise exec -- pre-commit run -a` (terraform-docs regenerates the README block with the constraint, not the locked version)
- [ ] 8.7 Commit subject (becomes the CHANGELOG line): `Collapse inputs into objects and add VPC routes, port forwarding and a dual-stack ACL`; body: `BREAKING:` paragraph summarising renamed/removed inputs and outputs, project_id, bastion range, ACL default rule, and a pointer to the README "Upgrading from v1 to v2"; release as v2.0.0 (signed tag, release process)

## 9. Real-account checks (separate, needs a sandbox Scaleway project; skipped unless asked)

- [ ] 9.1 Apply v1.3.0 `examples/complete`, then switch to this change with the new inputs: plan shows only the gateway and unnamed-network renames and the ACL `moved`; apply; second plan empty
- [ ] 9.2 Bastion off: plan against a v1.3.0 state shows no diff on `bastion_port` / `allowed_ip_ranges`; otherwise apply the fallback in the design Risks
- [ ] 9.3 ACL with a port-0 rule, IPv6 ACL and a rule with `description`: second plan empty
- [ ] 9.4 PAT rule (`protocol = "both"` casing), route with `nexthop_private_network` and with `nexthop_resource_id`: second plan empty
- [ ] 9.5 `flexible_ip_ids` with an existing IP in one zone; `VPC-GW-L` gateway if quota allows
- [ ] 9.6 Destroy the sandbox resources
