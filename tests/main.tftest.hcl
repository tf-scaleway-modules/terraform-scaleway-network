mock_provider "scaleway" {
  mock_resource "scaleway_vpc" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_private_network" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_public_gateway" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_public_gateway_ip" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_ipam_ip" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_gateway_network" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_acl" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_public_gateway_pat_rule" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
  mock_resource "scaleway_vpc_route" {
    defaults = {
      id = "fr-par-1/44444444-4444-4444-4444-444444444444"
    }
  }
}

variables {
  name = "test"
}

run "minimal_plan" {
  command = plan

  assert {
    condition     = length(output.gateway_ids) == 0 && length(output.access_control_list_ids) == 0 && length(output.route_ids) == 0 && length(output.pat_rule_ids) == 0
    error_message = "Minimal call must plan no gateway, ACL, route or PAT rule."
  }

  assert {
    condition     = length(scaleway_vpc_private_network.this) == 1 && scaleway_vpc_private_network.this["default"].name == "test-default"
    error_message = "Minimal call must plan one private network named test-default."
  }
}

run "optional_blocks_unset_outputs_empty" {
  command = plan
  variables {
    gateway = null
  }

  assert {
    condition     = length(output.gateway_flexible_ip_ids) == 0 && length(output.gateway_network_ids) == 0 && length(output.ipam_ip_ids) == 0
    error_message = "Gateway, ACL and routes unset must plan empty maps."
  }
}

run "project_id_passed" {
  command = plan
  variables {
    region     = "fr-par"
    zones      = ["fr-par-1", "fr-par-2"]
    project_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = scaleway_vpc.this.project_id == "11111111-1111-1111-1111-111111111111" && scaleway_vpc_private_network.this["default"].project_id == "11111111-1111-1111-1111-111111111111"
    error_message = "VPC and private network must be planned in the given project."
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.project_id == "11111111-1111-1111-1111-111111111111"]) && alltrue([for i in scaleway_vpc_public_gateway_ip.this : i.project_id == "11111111-1111-1111-1111-111111111111"]) && alltrue([for i in scaleway_ipam_ip.this : i.project_id == "11111111-1111-1111-1111-111111111111"])
    error_message = "Gateways, flexible IPs and IPAM IPs must be planned in the given project."
  }
}

run "project_id_invalid" {
  command = plan
  variables {
    project_id = "default"
  }
  expect_failures = [var.project_id]
}

run "name_empty" {
  command = plan
  variables {
    name = ""
  }
  expect_failures = [var.name]
}

run "zones_in_region" {
  command = plan
  variables {
    region = "fr-par"
    zones  = ["fr-par-1", "fr-par-2"]
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway.this) == 2 && scaleway_vpc_public_gateway.this["fr-par-1"].name == "test-fr-par-1" && scaleway_vpc_public_gateway.this["fr-par-2"].name == "test-fr-par-2"
    error_message = "Two gateways named <name>-<zone> expected."
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway_ip.this) == 2
    error_message = "One reserved flexible IP per zone expected."
  }
}

run "zones_without_region" {
  command = plan
  variables {
    zones = ["fr-par-1", "fr-par-2"]
  }
}

run "empty_zones_with_region" {
  command = plan
  variables {
    region = "fr-par"
    zones  = []
  }
}

run "zone_outside_region" {
  command = plan
  variables {
    region = "fr-par"
    zones  = ["nl-ams-1"]
  }
  expect_failures = [var.zones]
}

run "mixed_regions_without_region" {
  command = plan
  variables {
    zones = ["fr-par-1", "nl-ams-1"]
  }
  expect_failures = [var.zones]
}

run "zone_empty_string" {
  command = plan
  variables {
    zones = [""]
  }
  expect_failures = [var.zones]
}

run "private_network_names_and_tags" {
  command = plan
  variables {
    tags = ["prod"]
    private_networks = {
      web = { name = "web-network", tags = ["web"] }
      app = { tags = ["prod", "app"] }
    }
  }

  assert {
    condition     = scaleway_vpc_private_network.this["web"].name == "web-network" && scaleway_vpc_private_network.this["app"].name == "test-app"
    error_message = "Named network keeps its name, unnamed one is <name>-<key>."
  }

  assert {
    condition     = scaleway_vpc_private_network.this["web"].tags == tolist(["prod", "web"]) && scaleway_vpc_private_network.this["app"].tags == tolist(["prod", "app"])
    error_message = "Tags must be the distinct union of tags and network tags."
  }
}

run "private_networks_empty" {
  command = plan
  variables {
    private_networks = {}
  }

  assert {
    condition     = length(output.private_network_ids) == 0
    error_message = "No private network must be planned."
  }
}

run "private_network_subnets" {
  command = plan
  variables {
    private_networks = {
      web = { ipv4_subnet = "10.0.1.0/24", ipv6_subnet = "2001:db8::/64" }
    }
  }

  assert {
    condition     = scaleway_vpc_private_network.this["web"].ipv4_subnet[0].subnet == "10.0.1.0/24"
    error_message = "Fixed IPv4 subnet expected."
  }
}

run "private_network_invalid_ipv4_subnet" {
  command = plan
  variables {
    private_networks = { web = { ipv4_subnet = "10.0.1.0/33" } }
  }
  expect_failures = [var.private_networks]
}

run "private_network_invalid_ipv6_subnet" {
  command = plan
  variables {
    private_networks = { web = { ipv6_subnet = "10.0.1.0/24" } }
  }
  expect_failures = [var.private_networks]
}

run "ipv6_output_without_subnet" {
  command = plan
  variables {
    private_networks = { web = {} }
  }
}

run "network_default_route_propagation_set" {
  command = plan
  variables {
    private_networks = {
      web = { enable_default_route_propagation = true }
      app = {}
    }
  }

  assert {
    condition     = scaleway_vpc_private_network.this["web"].enable_default_route_propagation == true
    error_message = "web must be planned with default route propagation enabled."
  }

  assert {
    condition     = try(var.private_networks["app"].enable_default_route_propagation, null) == null
    error_message = "app must leave default route propagation unset."
  }
}

run "network_default_route_propagation_unset" {
  command = plan

  assert {
    condition     = try(var.private_networks["default"].enable_default_route_propagation, null) == null
    error_message = "Default input must leave default route propagation unset."
  }
}

run "vpc_transitivity_default" {
  command = plan

  assert {
    condition     = scaleway_vpc.this.enable_transitivity == false
    error_message = "Transitivity must default to false."
  }
}

run "vpc_transitivity_enabled" {
  command = plan
  variables {
    enable_transitivity = true
  }

  assert {
    condition     = scaleway_vpc.this.enable_transitivity == true
    error_message = "Transitivity must be enabled."
  }
}

run "gateway_disabled" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = null
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway.this) == 0 && length(scaleway_vpc_public_gateway_ip.this) == 0 && length(scaleway_ipam_ip.this) == 0 && length(scaleway_vpc_gateway_network.this) == 0 && length(scaleway_vpc_public_gateway_pat_rule.this) == 0
    error_message = "No gateway resource must be planned when gateway is null."
  }
}

run "gateway_attachments" {
  command = plan
  variables {
    region           = "fr-par"
    zones            = ["fr-par-1", "fr-par-2"]
    private_networks = { web = {}, app = {} }
  }

  assert {
    condition     = length(scaleway_vpc_gateway_network.this) == 4 && length(scaleway_ipam_ip.this) == 4
    error_message = "Four attachments and IPAM IPs expected."
  }
}

run "gateway_masquerade_disabled" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { enable_masquerade = false }
  }

  assert {
    condition     = alltrue([for n in scaleway_vpc_gateway_network.this : n.enable_masquerade == false])
    error_message = "Masquerade must be disabled."
  }
}

run "gateway_smtp_and_refresh" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { enable_smtp = true, refresh_ssh_keys = "2" }
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.enable_smtp == true && g.refresh_ssh_keys == "2"])
    error_message = "SMTP and refresh trigger must be planned."
  }
}

run "gateway_type_medium" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { type = "VPC-GW-M" }
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.type == "VPC-GW-M"])
    error_message = "Gateways must be of type VPC-GW-M."
  }
}

run "gateway_type_large" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { type = "VPC-GW-L" }
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.type == "VPC-GW-L"])
    error_message = "Gateways must be of type VPC-GW-L."
  }
}

run "gateway_type_invalid" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { type = "VPC-GW-XXL" }
  }
  expect_failures = [var.gateway]
}

run "flexible_ip_existing_one_zone" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { flexible_ip_ids = { "fr-par-1" = "fr-par-1/33333333-3333-3333-3333-333333333333" } }
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway_ip.this) == 1 && contains(keys(scaleway_vpc_public_gateway_ip.this), "fr-par-2")
    error_message = "Only fr-par-2 must get a reserved IP."
  }

  assert {
    condition     = scaleway_vpc_public_gateway.this["fr-par-1"].ip_id == "fr-par-1/33333333-3333-3333-3333-333333333333"
    error_message = "fr-par-1 must use the given flexible IP."
  }
}

run "flexible_ip_zone_outside_zones" {
  command = plan
  variables {
    zones   = ["fr-par-1"]
    gateway = { flexible_ip_ids = { "nl-ams-1" = "nl-ams-1/33333333-3333-3333-3333-333333333333" } }
  }
  expect_failures = [var.gateway]
}

run "bastion_disabled_by_default" {
  command = plan
  variables {
    region = "fr-par"
    zones  = ["fr-par-1", "fr-par-2"]
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.bastion_enabled == false])
    error_message = "Bastion must be disabled by default."
  }
}

run "bastion_enabled" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { port = 2222, allowed_ip_ranges = ["203.0.113.0/24"] } }
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.bastion_enabled == true && g.bastion_port == 2222 && g.allowed_ip_ranges == toset(["203.0.113.0/24"])])
    error_message = "Bastion must be planned on port 2222 with the given range."
  }
}

run "bastion_default_port" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { allowed_ip_ranges = ["203.0.113.0/24"] } }
  }

  assert {
    condition     = alltrue([for g in scaleway_vpc_public_gateway.this : g.bastion_port == 61000])
    error_message = "Bastion port must default to 61000."
  }
}

run "bastion_port_zero" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { port = 0, allowed_ip_ranges = ["203.0.113.0/24"] } }
  }
  expect_failures = [var.gateway]
}

run "bastion_port_too_high" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { port = 70000, allowed_ip_ranges = ["203.0.113.0/24"] } }
  }
  expect_failures = [var.gateway]
}

run "bastion_no_allowed_ranges" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { allowed_ip_ranges = [] } }
  }
  expect_failures = [var.gateway]
}

run "bastion_invalid_range" {
  command = plan
  variables {
    region  = "fr-par"
    zones   = ["fr-par-1", "fr-par-2"]
    gateway = { bastion = { allowed_ip_ranges = ["anywhere"] } }
  }
  expect_failures = [var.gateway]
}

run "pat_rule_planned" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 22 }
      }
    }
  }

  assert {
    condition     = scaleway_vpc_public_gateway_pat_rule.this["ssh"].protocol == "both" && scaleway_vpc_public_gateway_pat_rule.this["ssh"].public_port == 2222 && scaleway_vpc_public_gateway_pat_rule.this["ssh"].zone == "fr-par-1"
    error_message = "One PAT rule with protocol both expected."
  }

  assert {
    condition     = length(output.pat_rule_ids) == 1
    error_message = "pat_rule_ids must hold the rule."
  }
}

run "pat_rule_invalid_protocol" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 22, protocol = "icmp" }
      }
    }
  }
  expect_failures = [var.gateway]
}

run "pat_rule_public_port_zero" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "fr-par-1", public_port = 0, private_ip = "10.0.0.5", private_port = 22 }
      }
    }
  }
  expect_failures = [var.gateway]
}

run "pat_rule_private_port_too_high" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 70000 }
      }
    }
  }
  expect_failures = [var.gateway]
}

run "pat_rule_duplicate_public_port" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 22 }
        web = { zone = "fr-par-1", public_port = 2222, private_ip = "10.0.0.6", private_port = 80 }
      }
    }
  }
  expect_failures = [var.gateway]
}

run "pat_rule_unknown_zone" {
  command = plan
  variables {
    zones = ["fr-par-1"]
    gateway = {
      pat_rules = {
        ssh = { zone = "nl-ams-1", public_port = 2222, private_ip = "10.0.0.5", private_port = 22 }
      }
    }
  }
  expect_failures = [var.gateway]
}

run "acl_disabled_by_default" {
  command = plan

  assert {
    condition     = length(scaleway_vpc_acl.this) == 0
    error_message = "No ACL must be planned by default."
  }
}

run "acl_ipv4_only" {
  command = plan
  variables {
    access_control_list = { ipv4 = {} }
  }

  assert {
    condition     = length(scaleway_vpc_acl.this) == 1 && scaleway_vpc_acl.this["ipv4"].is_ipv6 == false && scaleway_vpc_acl.this["ipv4"].default_policy == "accept"
    error_message = "One IPv4 ACL with policy accept expected."
  }

  assert {
    condition     = length(scaleway_vpc_acl.this["ipv4"].rules) == 0
    error_message = "The ACL must have no default rule."
  }

  assert {
    condition     = contains(keys(output.access_control_list_ids), "ipv4")
    error_message = "access_control_list_ids must have the key ipv4."
  }
}

run "acl_ipv6_only" {
  command = plan
  variables {
    access_control_list = { ipv6 = {} }
  }

  assert {
    condition     = length(scaleway_vpc_acl.this) == 1 && scaleway_vpc_acl.this["ipv6"].is_ipv6 == true
    error_message = "One IPv6 ACL expected."
  }
}

run "acl_both_families" {
  command = plan
  variables {
    access_control_list = { ipv4 = {}, ipv6 = {} }
  }

  assert {
    condition     = length(scaleway_vpc_acl.this) == 2 && scaleway_vpc_acl.this["ipv6"].is_ipv6 == true && scaleway_vpc_acl.this["ipv4"].is_ipv6 == false
    error_message = "Two ACLs expected."
  }
}

run "acl_region" {
  command = plan
  variables {
    region              = "nl-ams"
    access_control_list = { ipv4 = {} }
  }

  assert {
    condition     = scaleway_vpc_acl.this["ipv4"].region == "nl-ams"
    error_message = "The ACL must follow region."
  }
}

run "acl_drop_policy" {
  command = plan
  variables {
    access_control_list = { ipv4 = { default_policy = "drop" } }
  }

  assert {
    condition     = scaleway_vpc_acl.this["ipv4"].default_policy == "drop"
    error_message = "Drop policy expected."
  }
}

run "acl_invalid_policy" {
  command = plan
  variables {
    access_control_list = { ipv4 = { default_policy = "reject" } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_rules_ports_default_zero" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "0.0.0.0/0", destination = "0.0.0.0/0", action = "accept", protocol = "TCP", dst_port_low = 80, dst_port_high = 80 }, { source = "10.0.0.0/8", destination = "0.0.0.0/0", action = "drop", description = "ping", protocol = "ICMP" }] } }
  }

  assert {
    condition     = length(scaleway_vpc_acl.this["ipv4"].rules) == 2 && scaleway_vpc_acl.this["ipv4"].rules[0].src_port_low == 0 && scaleway_vpc_acl.this["ipv4"].rules[0].dst_port_high == 80 && scaleway_vpc_acl.this["ipv4"].rules[1].description == "ping"
    error_message = "Two rules in order with source ports 0 expected."
  }
}

run "acl_invalid_protocol" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "0.0.0.0/0", destination = "0.0.0.0/0", action = "accept", protocol = "SCTP" }] } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_invalid_action" {
  command = plan
  variables {
    access_control_list = { ipv6 = { rules = [{ source = "::/0", destination = "::/0", action = "reject" }] } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_inverted_port_range" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "0.0.0.0/0", destination = "0.0.0.0/0", action = "accept", dst_port_low = 90, dst_port_high = 80 }] } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_port_out_of_range" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "0.0.0.0/0", destination = "0.0.0.0/0", action = "accept", dst_port_high = 70000 }] } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_invalid_source_cidr" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "any", destination = "0.0.0.0/0", action = "accept" }] } }
  }
  expect_failures = [var.access_control_list]
}

run "acl_invalid_destination_cidr" {
  command = plan
  variables {
    access_control_list = { ipv4 = { rules = [{ source = "0.0.0.0/0", destination = "10.0.0.0/40", action = "accept" }] } }
  }
  expect_failures = [var.access_control_list]
}

run "routes_unset" {
  command = plan

  assert {
    condition     = length(scaleway_vpc_route.this) == 0 && length(output.route_ids) == 0
    error_message = "No route must be planned by default."
  }
}

run "route_private_network_nexthop" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      appliance = { destination = "192.168.0.0/16", nexthop_private_network = "app", tags = ["x"] }
    }
  }

  assert {
    condition     = scaleway_vpc_route.this["appliance"].nexthop_private_network_id == scaleway_vpc_private_network.this["app"].id
    error_message = "Route must go through the app network."
  }

  assert {
    condition     = scaleway_vpc_route.this["appliance"].destination == "192.168.0.0/16"
    error_message = "Destination expected."
  }

  assert {
    condition     = length(output.route_ids) == 1
    error_message = "route_ids must hold the route."
  }
}

run "route_resource_nexthop" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "192.168.0.0/16", nexthop_resource_id = "fr-par-1/55555555-5555-5555-5555-555555555555" }
    }
  }

  assert {
    condition     = scaleway_vpc_route.this["r"].nexthop_resource_id == "fr-par-1/55555555-5555-5555-5555-555555555555"
    error_message = "Route must use the resource next hop."
  }
}

run "route_connector_nexthop" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "192.168.0.0/16", nexthop_vpc_connector_id = "fr-par/66666666-6666-6666-6666-666666666666" }
    }
  }

  assert {
    condition     = scaleway_vpc_route.this["r"].nexthop_vpc_connector_id == "fr-par/66666666-6666-6666-6666-666666666666"
    error_message = "Route must use the connector next hop."
  }
}

run "route_two_nexthops" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "192.168.0.0/16", nexthop_resource_id = "a", nexthop_vpc_connector_id = "b" }
    }
  }
  expect_failures = [var.routes]
}

run "route_no_nexthop" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "192.168.0.0/16" }
    }
  }
  expect_failures = [var.routes]
}

run "route_invalid_destination" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "10.0.0.0/40", nexthop_private_network = "app" }
    }
  }
  expect_failures = [var.routes]
}

run "route_unknown_private_network" {
  command = plan
  variables {
    private_networks = { app = {} }
    routes = {
      r = { destination = "192.168.0.0/16", nexthop_private_network = "missing" }
    }
  }
  expect_failures = [var.routes]
}
