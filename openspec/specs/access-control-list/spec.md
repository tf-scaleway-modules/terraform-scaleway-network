# access-control-list Specification

## Purpose
Optional VPC access control list: creation flag, default policy, IP family and rules.

## Requirements

### Requirement: Conditional ACL
The module SHALL create one `scaleway_vpc_acl` on the VPC per IP family set in `access_control_list` (nullable object, default `null`, with optional `ipv4` and `ipv6` objects), keyed `ipv4` or `ipv6`. `access_control_list_ids` SHALL map each created family to its ACL ID and is empty otherwise. The ACL is placed in `region`.

#### Scenario: Disabled by default
- **WHEN** `access_control_list` is not set
- **THEN** no ACL is planned and `access_control_list_ids` is empty

#### Scenario: Enabled
- **WHEN** `access_control_list = { ipv4 = {} }`
- **THEN** one ACL is planned on the VPC and `access_control_list_ids` has the key `ipv4`

#### Scenario: IPv4 only
- **WHEN** `access_control_list = { ipv4 = {} }`
- **THEN** one ACL is planned for IPv4 and `access_control_list_ids` has the key `ipv4`

#### Scenario: Both families
- **WHEN** `access_control_list = { ipv4 = {}, ipv6 = {} }`
- **THEN** two ACLs are planned, one with `is_ipv6 = true`

### Requirement: ACL policy and IP family
Each family object SHALL have a `default_policy` (default `accept`), which MUST be `accept` or `drop`. The `ipv6` family SHALL be planned with `is_ipv6 = true`, the `ipv4` family with `is_ipv6 = false`.

#### Scenario: Invalid policy
- **WHEN** `access_control_list = { ipv4 = { default_policy = "reject" } }`
- **THEN** the plan fails with "ACL default policy must be either 'accept' or 'drop'."

#### Scenario: Drop policy
- **WHEN** `access_control_list = { ipv4 = { default_policy = "drop" } }`
- **THEN** the ACL is planned with the default policy `drop`

#### Scenario: IPv6 ACL
- **WHEN** `access_control_list = { ipv6 = {} }`
- **THEN** the ACL is planned for IPv6 traffic

### Requirement: ACL rules
Each family SHALL contain one rule per element of its `rules` (list, default `[]`, no default rule) with required `source`, `destination` and `action`, and optional `protocol` (default `ANY`), `src_port_low`, `src_port_high`, `dst_port_low`, `dst_port_high` (default `0`, any port) and `description` (default null).

#### Scenario: Default rule
- **WHEN** a family is set and its rules are not set
- **THEN** the ACL is planned with no rule (no default rule exists) and only its default policy applies

#### Scenario: Rules ignored when disabled
- **WHEN** `access_control_list = null`
- **THEN** no ACL is planned

#### Scenario: Custom rules
- **WHEN** `rules` holds two rules
- **THEN** the ACL is planned with those two rules, in order

#### Scenario: Port defaults
- **WHEN** a rule sets only `protocol`, `source`, `destination`, `action` and `dst_port_low = 80`, `dst_port_high = 80`
- **THEN** the source ports are planned as `0`

### Requirement: ACL rule values
Every rule `protocol` MUST be one of `ANY`, `TCP`, `UDP` or `ICMP`, every `action` `accept` or `drop`, every port between 0 and 65535 with each low port not above its high port, and `source` and `destination` valid CIDR blocks.

#### Scenario: Invalid protocol
- **WHEN** a rule has `protocol = "SCTP"`
- **THEN** the plan fails with "ACL rule protocol must be one of 'ANY', 'TCP', 'UDP' or 'ICMP' and action must be 'accept' or 'drop'."

#### Scenario: Invalid action
- **WHEN** a rule has `action = "reject"`
- **THEN** the plan fails with the same error message

#### Scenario: Inverted port range
- **WHEN** a rule has `dst_port_low = 90` and `dst_port_high = 80`
- **THEN** the plan fails with "ACL rule ports must be between 0 and 65535 and low must not exceed high."

#### Scenario: Invalid values while disabled
- **WHEN** `access_control_list = null`
- **THEN** the plan succeeds and no ACL is planned

#### Scenario: Invalid CIDR
- **WHEN** a rule has `source = "any"`
- **THEN** the plan fails with "ACL rule source and destination must be valid CIDR blocks."
