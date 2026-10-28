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
}

override_data {
  target = data.scaleway_account_project.project
  values = {
    id = "11111111-1111-1111-1111-111111111111"
  }
}

variables {
  organization_id = "22222222-2222-2222-2222-222222222222"
  project_name    = "default"
  vpc_name        = "test"
}

run "minimal_plan" {
  command = plan

  assert {
    condition     = length(output.gateway_ids) == 0 && output.access_control_list_id == null
    error_message = "Minimal call must plan no gateway and no ACL."
  }
}

run "zones_in_region" {
  command = plan
  variables {
    vpc_region = "fr-par"
    vpc_zones  = ["fr-par-1", "fr-par-2"]
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway.this) == 2 && alltrue([for g in scaleway_vpc_public_gateway.this : g.name == "test"])
    error_message = "Two gateways named after vpc_name expected."
  }
}

run "zones_without_region" {
  command = plan
  variables {
    vpc_zones = ["fr-par-1", "fr-par-2"]
  }
}

run "empty_zones_with_region" {
  command = plan
  variables {
    vpc_region = "fr-par"
    vpc_zones  = []
  }
}

run "zone_outside_region" {
  command = plan
  variables {
    vpc_region = "fr-par"
    vpc_zones  = ["nl-ams-1"]
  }
  expect_failures = [var.vpc_zones]
}

run "mixed_regions_without_region" {
  command = plan
  variables {
    vpc_zones = ["fr-par-1", "nl-ams-1"]
  }
  expect_failures = [var.vpc_zones]
}

run "acl_invalid_protocol" {
  command = plan
  variables {
    enable_access_control_list = true
    access_control_list_rules = [{
      protocol      = "SCTP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 80
      dst_port_high = 80
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "bad protocol"
      action        = "accept"
    }]
  }
  expect_failures = [var.access_control_list_rules]
}

run "acl_invalid_action" {
  command = plan
  variables {
    enable_access_control_list = true
    access_control_list_rules = [{
      protocol      = "TCP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 80
      dst_port_high = 80
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "bad action"
      action        = "reject"
    }]
  }
  expect_failures = [var.access_control_list_rules]
}

run "acl_valid_rules" {
  command = plan
  variables {
    enable_access_control_list = true
    access_control_list_rules = [{
      protocol      = "ICMP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 0
      dst_port_high = 0
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "ping"
      action        = "drop"
    }]
  }

  assert {
    condition     = length(scaleway_vpc_acl.this) == 1
    error_message = "ACL must be planned."
  }
}

run "acl_disabled_ignores_invalid_rules" {
  command = plan
  variables {
    enable_access_control_list = false
    access_control_list_rules = [{
      protocol      = "SCTP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 80
      dst_port_high = 80
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "ignored"
      action        = "reject"
    }]
  }

  assert {
    condition     = length(scaleway_vpc_acl.this) == 0
    error_message = "No ACL must be planned when disabled."
  }
}

run "flexible_ip_conflict_warns" {
  command = plan
  variables {
    vpc_region                      = "fr-par"
    vpc_zones                       = ["fr-par-1"]
    gateway_reserve_flexible_ip     = true
    gateway_existing_flexible_ip_id = "fr-par-1/33333333-3333-3333-3333-333333333333"
  }
  expect_failures = [check.gateway_flexible_ip]
}

run "flexible_ip_existing_no_warning" {
  command = plan
  variables {
    vpc_region                      = "fr-par"
    vpc_zones                       = ["fr-par-1"]
    gateway_reserve_flexible_ip     = false
    gateway_existing_flexible_ip_id = "fr-par-1/33333333-3333-3333-3333-333333333333"
  }

  assert {
    condition     = length(scaleway_vpc_public_gateway_ip.this) == 0
    error_message = "No flexible IP must be reserved."
  }
}

run "ipv6_output_without_subnet" {
  command = plan
  variables {
    network_private_networks = {
      web = {}
    }
  }
}

run "vpc_flags_default_no_warning" {
  command = plan

  assert {
    condition     = scaleway_vpc.this.enable_transitivity == false
    error_message = "Defaults must plan the VPC without a deprecation warning."
  }
}

run "vpc_routing_flag_warns" {
  command = plan
  variables {
    vpc_enable_routing = true
  }
  expect_failures = [check.vpc_deprecated_routing_flags]
}

run "vpc_custom_routes_flag_warns" {
  command = plan
  variables {
    vpc_enable_custom_routes = true
  }
  expect_failures = [check.vpc_deprecated_routing_flags]
}

run "network_default_route_propagation_set" {
  command = plan
  variables {
    network_private_networks = {
      web = { enable_default_route_propagation = true }
      app = {}
    }
  }

  assert {
    condition     = scaleway_vpc_private_network.this["web"].enable_default_route_propagation == true
    error_message = "web must be planned with default route propagation enabled."
  }

  assert {
    condition     = try(var.network_private_networks["app"].enable_default_route_propagation, null) == null
    error_message = "app must leave default route propagation unset."
  }
}

run "network_default_route_propagation_unset" {
  command = plan

  assert {
    condition     = try(var.network_private_networks["default"].enable_default_route_propagation, null) == null
    error_message = "Default input must leave default route propagation unset."
  }
}
