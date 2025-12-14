# ==============================================================================
# Scaleway VPC Terraform Module
# ==============================================================================
# This module creates and manages a complete Scaleway VPC infrastructure:
#
# - Virtual Private Cloud (VPC) with routing capabilities
# - Multiple private networks with customizable subnets (IPv4/IPv6)
# - Public gateways for internet connectivity (multi-zone support)
# - Access Control Lists (ACLs) for traffic filtering
# - SSH bastion host configuration
# - IPAM IP management for gateway-network attachments
#
# Resource Hierarchy:
#   VPC (region-scoped)
#    ├── Access Control Lists (optional)
#    ├── Private Networks (1 to N)
#    │    ├── IPv4/IPv6 Subnets
#    │    └── Network Tags
#    └── Public Gateways (0 to N, one per zone)
#         ├── Flexible IPs
#         ├── IPAM IPs (for each network-zone pair)
#         └── Gateway Network Attachments
# ==============================================================================

# ==============================================================================
# VPC Foundation Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Core Resource
# ------------------------------------------------------------------------------
# Creates the main VPC container for all private networks.
# Routing and custom route propagation can be enabled for inter-network traffic.
# WARNING: Routing cannot be disabled once enabled.

resource "scaleway_vpc" "this" {
  name       = var.vpc_name
  project_id = data.scaleway_account_project.project.id
  region     = var.vpc_region
  tags       = local.common_tags

  enable_routing                   = var.vpc_enable_routing
  enable_custom_routes_propagation = var.vpc_enable_custom_routes
}

# ------------------------------------------------------------------------------
# Access Control List (ACL)
# ------------------------------------------------------------------------------
# Optional VPC-level firewall for traffic filtering.
# Provides stateful firewall capabilities with customizable rules.

resource "scaleway_vpc_acl" "this" {
  count = var.enable_access_control_list ? 1 : 0

  vpc_id         = scaleway_vpc.this.id
  is_ipv6        = var.access_control_list_is_ipv6
  default_policy = var.access_control_list_default_policy

  # Traffic filtering rules (protocol, ports, source/destination, action)
  dynamic "rules" {
    for_each = var.access_control_list_rules
    content {
      protocol      = rules.value.protocol
      src_port_low  = rules.value.src_port_low
      src_port_high = rules.value.src_port_high
      dst_port_low  = rules.value.dst_port_low
      dst_port_high = rules.value.dst_port_high
      source        = rules.value.source
      destination   = rules.value.destination
      description   = rules.value.description
      action        = rules.value.action
    }
  }
}

# ==============================================================================
# Network Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# Private Networks
# ------------------------------------------------------------------------------
# Creates isolated private networks within the VPC.
# Each network supports custom IPv4/IPv6 subnets or auto-assignment.
# Use for tier segmentation (e.g., web, app, database).

resource "scaleway_vpc_private_network" "this" {
  for_each = var.network_private_networks

  name       = each.value.name
  vpc_id     = scaleway_vpc.this.id
  project_id = data.scaleway_account_project.project.id
  region     = var.vpc_region
  tags       = concat(local.common_tags, each.value.tags)

  # IPv4 subnet (optional, auto-assigns /22 if not specified)
  dynamic "ipv4_subnet" {
    for_each = each.value.ipv4_subnet != null ? [1] : []
    content {
      subnet = each.value.ipv4_subnet
    }
  }

  # IPv6 subnet (optional, auto-assigns /64 if not specified)
  dynamic "ipv6_subnets" {
    for_each = each.value.ipv6_subnet != null ? [1] : []
    content {
      subnet = each.value.ipv6_subnet
    }
  }
}

# ==============================================================================
# Gateway Infrastructure Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# Gateway Flexible IPs
# ------------------------------------------------------------------------------
# Reserves static public IP addresses for gateways (one per zone).
# Only created when gateway is enabled and IP reservation is requested.

resource "scaleway_vpc_public_gateway_ip" "this" {
  for_each = local.gateway_ip_zones

  zone       = each.value
  project_id = data.scaleway_account_project.project.id
  tags       = local.common_tags
}

# ------------------------------------------------------------------------------
# Public Gateways
# ------------------------------------------------------------------------------
# Creates NAT gateways for internet connectivity (one per zone).
# Supports SSH bastion access and SMTP relay functionality.

resource "scaleway_vpc_public_gateway" "this" {
  for_each = local.gateway_zones

  name       = var.vpc_name
  type       = var.gateway_type
  zone       = each.value
  project_id = data.scaleway_account_project.project.id
  tags       = local.common_tags

  # Flexible IP attachment (reserved or existing)
  ip_id = var.gateway_reserve_flexible_ip ? scaleway_vpc_public_gateway_ip.this[each.value].id : var.gateway_existing_flexible_ip_id

  # SSH bastion configuration
  bastion_enabled   = var.enable_bastion
  bastion_port      = var.bastion_ssh_port
  allowed_ip_ranges = var.bastion_allowed_ip_ranges

  # SMTP configuration (port 25 for email)
  enable_smtp = var.gateway_enable_smtp

  # SSH key refresh trigger
  refresh_ssh_keys = var.gateway_refresh_ssh_keys
}

# ------------------------------------------------------------------------------
# IPAM IPs
# ------------------------------------------------------------------------------
# Allocates IP addresses for gateway-network connections.
# Creates one IPAM IP per network-zone combination (N networks × Z zones).

resource "scaleway_ipam_ip" "this" {
  for_each = local.network_zone_pairs

  is_ipv6    = false
  region     = var.vpc_region
  project_id = data.scaleway_account_project.project.id
  tags       = local.common_tags

  source {
    private_network_id = scaleway_vpc_private_network.this[each.value.network_key].id
  }
}

# ------------------------------------------------------------------------------
# Gateway Network Attachments
# ------------------------------------------------------------------------------
# Connects gateways to private networks with NAT (masquerade).
# Creates one attachment per network-zone combination (N × Z).

resource "scaleway_vpc_gateway_network" "this" {
  for_each = local.network_zone_pairs

  gateway_id         = scaleway_vpc_public_gateway.this[each.value.zone].id
  private_network_id = scaleway_vpc_private_network.this[each.value.network_key].id
  zone               = each.value.zone

  # Enable NAT for outbound internet access
  enable_masquerade = var.gateway_enable_masquerade

  # IPAM configuration for IP allocation
  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.this["${each.value.network_key}-${each.value.zone}"].id
  }
}
