## MODIFIED Requirements

### Requirement: ACL rules
The ACL SHALL contain one rule per element of `access_control_list_rules` (list of objects with `protocol`, `src_port_low`, `src_port_high`, `dst_port_low`, `dst_port_high`, `source`, `destination`, `description` and `action`, all required). The default list holds one TCP rule accepting port 80 from and to `0.0.0.0/0`. When `enable_access_control_list` is true, every `protocol` MUST be one of `ANY`, `TCP`, `UDP` or `ICMP` and every `action` MUST be `accept` or `drop`. The values are not validated while the ACL is disabled, because the rules are then unused.

#### Scenario: Default rule
- **WHEN** the ACL is enabled and the rules are not set
- **THEN** the ACL has one rule allowing TCP destination port 80 from any source

#### Scenario: Custom rules
- **WHEN** `access_control_list_rules` holds two rules
- **THEN** the ACL is planned with those two rules, in order

#### Scenario: Rules ignored when disabled
- **WHEN** `enable_access_control_list = false` and rules are given
- **THEN** no ACL is planned

#### Scenario: Invalid protocol
- **WHEN** `enable_access_control_list = true` and a rule has `protocol = "SCTP"`
- **THEN** the plan fails with "ACL rule protocol must be one of 'ANY', 'TCP', 'UDP' or 'ICMP' and action must be 'accept' or 'drop'."

#### Scenario: Invalid action
- **WHEN** `enable_access_control_list = true` and a rule has `action = "reject"`
- **THEN** the plan fails with the same error message

#### Scenario: Invalid values while disabled
- **WHEN** `enable_access_control_list = false` and a rule has `protocol = "SCTP"`
- **THEN** the plan succeeds and no ACL is planned
