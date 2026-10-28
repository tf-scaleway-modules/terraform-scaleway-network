## 1. Code
- [x] 1.1 `outputs.tf`: `network_ipv6_cidrs` without `coalescelist`
- [x] 1.2 `variables.tf`: validation on `access_control_list_rules`; descriptions of `vpc_name`, `gateway_existing_flexible_ip_id`, `access_control_list_rules`
- [x] 1.3 `main.tf`: `check "gateway_flexible_ip"` warning
- [x] 1.4 `README.md`: release badge and link point to `scaleway-network`

## 2. Tests and examples
- [x] 2.1 `tests/main.tftest.hcl`: `vpc_zones` runs (5 accepted/rejected cases), ACL protocol/action rejected, disabled ACL accepted, check warning, IPv6 output, happy path
- [x] 2.2 `examples/complete`: show an `ANY`/`ICMP` rule; keep valid

## 3. Verify
- [x] 3.1 `tofu fmt -recursive`, `tofu validate`, `tofu test`, `tflint --recursive`, `pre-commit run -a`
- [x] 3.2 Commit subject: "Fix empty IPv6 output, validate ACL rules and clarify flexible IP and gateway name docs" (patch)
