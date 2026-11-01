# ==============================================================================
# Scaleway VPC Terraform Module
# ==============================================================================
# This module creates and manages a complete Scaleway VPC infrastructure:
#
# - Virtual Private Cloud (VPC) with routing capabilities
# - Multiple private networks with customizable subnets (IPv4/IPv6)
# - Public gateways for internet connectivity (multi-zone support)
# - Access Control Lists (ACLs) for traffic filtering, one per IP family
# - Custom routes with a next hop
# - SSH bastion host configuration and port forwarding (PAT) rules
# - IPAM IP management for gateway-network attachments
#
# Resource Hierarchy:
#   VPC (region-scoped)
#    ├── Access Control Lists (optional, IPv4 and/or IPv6)
#    ├── Private Networks (1 to N)
#    │    ├── IPv4/IPv6 Subnets
#    │    └── Network Tags
#    ├── Routes (optional)
#    └── Public Gateways (0 to N, one per zone)
#         ├── Flexible IPs
#         ├── IPAM IPs (for each network-zone pair)
#         ├── Gateway Network Attachments
#         └── PAT rules (optional)
# ==============================================================================

# ==============================================================================
# VPC Foundation Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC Core Resource
# ------------------------------------------------------------------------------
# Creates the main VPC container for all private networks.
# The provider enables routing and custom route propagation itself.

resource "scaleway_vpc" "this" {
  name       = var.name
  project_id = var.project_id
  region     = var.region
  tags       = var.tags

  enable_transitivity = var.enable_transitivity
}

# ------------------------------------------------------------------------------
# Access Control List (ACL)
# ------------------------------------------------------------------------------
# Optional VPC-level firewall for traffic filtering.
# A VPC holds at most one ACL per IP family, so the families are the keys.

moved {
  from = scaleway_vpc_acl.this[0]
  to   = scaleway_vpc_acl.this["ipv4"]
}

resource "scaleway_vpc_acl" "this" {
  for_each = local.access_control_lists

  vpc_id         = scaleway_vpc.this.id
  region         = var.region
  is_ipv6        = each.key == "ipv6"
  default_policy = each.value.default_policy

  # Traffic filtering rules (protocol, ports, source/destination, action)
  dynamic "rules" {
    for_each = each.value.rules
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
  for_each = var.private_networks

  name       = coalesce(each.value.name, "${var.name}-${each.key}")
  vpc_id     = scaleway_vpc.this.id
  project_id = var.project_id
  region     = var.region
  tags       = distinct(concat(var.tags, each.value.tags))

  enable_default_route_propagation = each.value.enable_default_route_propagation

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

# ------------------------------------------------------------------------------
# Routes
# ------------------------------------------------------------------------------
# Custom routes with exactly one next hop: a private network of this module
# (by key), any resource ID or a VPC connector ID.

resource "scaleway_vpc_route" "this" {
  for_each = var.routes

  vpc_id      = scaleway_vpc.this.id
  region      = var.region
  destination = each.value.destination
  description = each.value.description

  nexthop_private_network_id = each.value.nexthop_private_network == null ? null : scaleway_vpc_private_network.this[each.value.nexthop_private_network].id
  nexthop_resource_id        = each.value.nexthop_resource_id
  nexthop_vpc_connector_id   = each.value.nexthop_vpc_connector_id

  tags = distinct(concat(var.tags, each.value.tags))
}

# ==============================================================================
# Gateway Infrastructure Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# Gateway Flexible IPs
# ------------------------------------------------------------------------------
# Reserves public IP addresses for gateways, one per zone without a
# caller-supplied flexible IP (gateway.flexible_ip_ids).

resource "scaleway_vpc_public_gateway_ip" "this" {
  for_each = local.reserved_ip_zones

  zone       = each.value
  project_id = var.project_id
  tags       = var.tags
}

# ------------------------------------------------------------------------------
# Public Gateways
# ------------------------------------------------------------------------------
# Creates NAT gateways for internet connectivity (one per zone).
# Supports SSH bastion access and SMTP relay functionality.

resource "scaleway_vpc_public_gateway" "this" {
  for_each = local.gateway_zones

  name       = "${var.name}-${each.value}"
  type       = var.gateway.type
  zone       = each.value
  project_id = var.project_id
  tags       = var.tags

  # Flexible IP attachment (reserved or existing)
  ip_id = contains(local.reserved_ip_zones, each.value) ? scaleway_vpc_public_gateway_ip.this[each.value].id : var.gateway.flexible_ip_ids[each.value]

  # SSH bastion configuration; the splat yields null when the bastion is off,
  # which leaves both arguments to the provider
  bastion_enabled   = var.gateway.bastion != null
  bastion_port      = one(var.gateway.bastion[*].port)
  allowed_ip_ranges = one(var.gateway.bastion[*].allowed_ip_ranges)

  # SMTP configuration (port 25 for email)
  enable_smtp = var.gateway.enable_smtp

  # SSH key refresh trigger
  refresh_ssh_keys = var.gateway.refresh_ssh_keys
}

# ------------------------------------------------------------------------------
# IPAM IPs
# ------------------------------------------------------------------------------
# Allocates IP addresses for gateway-network connections.
# Creates one IPAM IP per network-zone combination (N networks × Z zones).

resource "scaleway_ipam_ip" "this" {
  for_each = local.network_zone_pairs

  is_ipv6    = false
  region     = var.region
  project_id = var.project_id
  tags       = var.tags

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
  enable_masquerade = var.gateway.enable_masquerade

  # IPAM configuration for IP allocation
  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.this["${each.value.network_key}-${each.value.zone}"].id
  }
}

# ------------------------------------------------------------------------------
# Port forwarding (PAT) rules
# ------------------------------------------------------------------------------
# Forwards a public gateway port to a private IP. The target must be reachable
# through an attached network, hence the dependency.

resource "scaleway_vpc_public_gateway_pat_rule" "this" {
  for_each = local.pat_rules

  gateway_id   = scaleway_vpc_public_gateway.this[each.value.zone].id
  zone         = each.value.zone
  public_port  = each.value.public_port
  private_ip   = each.value.private_ip
  private_port = each.value.private_port
  protocol     = each.value.protocol

  depends_on = [scaleway_vpc_gateway_network.this]
}
