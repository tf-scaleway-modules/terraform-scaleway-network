# access-control-list Specification

## Purpose
Optional VPC access control list: creation flag, default policy, IP family and rules.

## Requirements

### Requirement: Conditional ACL
The module SHALL create one `scaleway_vpc_acl` on the VPC only when `enable_access_control_list` (default `false`) is true. `access_control_list_id` SHALL be its ID, or null when it is not created.

#### Scenario: Disabled by default
- **WHEN** `enable_access_control_list` is not set
- **THEN** no ACL is planned and `access_control_list_id` is null

#### Scenario: Enabled
- **WHEN** `enable_access_control_list = true`
- **THEN** one ACL is planned on the VPC and `access_control_list_id` is its ID

### Requirement: ACL policy and IP family
The ACL SHALL use `access_control_list_default_policy` (default `accept`), which MUST be `accept` or `drop`, and `access_control_list_is_ipv6` (default `false`) to select IPv6 instead of IPv4.

#### Scenario: Invalid policy
- **WHEN** `access_control_list_default_policy = "reject"`
- **THEN** the plan fails with "ACL default policy must be either 'accept' or 'drop'."

#### Scenario: Drop policy
- **WHEN** `access_control_list_default_policy = "drop"`
- **THEN** the ACL is planned with the default policy `drop`

#### Scenario: IPv6 ACL
- **WHEN** `access_control_list_is_ipv6 = true`
- **THEN** the ACL is planned for IPv6 traffic

### Requirement: ACL rules
The ACL SHALL contain one rule per element of `access_control_list_rules` (list of objects with `protocol`, `src_port_low`, `src_port_high`, `dst_port_low`, `dst_port_high`, `source`, `destination`, `description` and `action`, all required). The default list holds one TCP rule accepting port 80 from and to `0.0.0.0/0`. The module SHALL NOT validate the protocol or action values itself.

#### Scenario: Default rule
- **WHEN** the ACL is enabled and the rules are not set
- **THEN** the ACL has one rule allowing TCP destination port 80 from any source

#### Scenario: Custom rules
- **WHEN** `access_control_list_rules` holds two rules
- **THEN** the ACL is planned with those two rules, in order

#### Scenario: Rules ignored when disabled
- **WHEN** `enable_access_control_list = false` and rules are given
- **THEN** no ACL is planned
