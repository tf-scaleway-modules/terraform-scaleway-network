# ==============================================================================
# VPC Core Outputs
# ==============================================================================

output "vpc_id" {
  description = "VPC resource identifier"
  value       = scaleway_vpc.this.id
}

# ==============================================================================
# Private Network Outputs
# ==============================================================================

output "network_private_network_ids" {
  description = "Private network IDs by network name"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => v.id
  }
}

output "network_ipv4_cidrs" {
  description = "IPv4 CIDR blocks by network name"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => try(v.ipv4_subnet[0].subnet, null)
  }
}

output "network_ipv6_cidrs" {
  description = "IPv6 CIDR blocks by network name"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => coalescelist(v.ipv6_subnets[*].subnet)
  }
}

# ==============================================================================
# Gateway Infrastructure Outputs
# ==============================================================================

output "gateway_ids" {
  description = "Public gateway IDs by zone"
  value = {
    for k, v in scaleway_vpc_public_gateway.this : k => v.id
  }
}

output "gateway_flexible_ip_ids" {
  description = "Gateway flexible IP resource IDs by zone"
  value = {
    for k, v in scaleway_vpc_public_gateway_ip.this : k => v.id
  }
}

output "gateway_flexible_ip_addresses" {
  description = "Gateway public IP addresses by zone"
  value = {
    for k, v in scaleway_vpc_public_gateway_ip.this : k => v.address
  }
}

output "gateway_network_ids" {
  description = "Gateway network attachment IDs by network-zone pair (e.g., web-fr-par-1)"
  value = {
    for k, v in scaleway_vpc_gateway_network.this : k => v.id
  }
}

# ==============================================================================
# IPAM Outputs
# ==============================================================================

output "ipam_ip_ids" {
  description = "IPAM IP resource IDs by network-zone pair"
  value = {
    for k, v in scaleway_ipam_ip.this : k => v.id
  }
}

output "ipam_ip_addresses" {
  description = "IPAM IP addresses by network-zone pair"
  value = {
    for k, v in scaleway_ipam_ip.this : k => v.address
  }
}

# ==============================================================================
# Access Control List Outputs
# ==============================================================================

output "access_control_list_id" {
  description = "VPC Access Control List ID (null if ACL not created)"
  value       = try(scaleway_vpc_acl.this[0].id, null)
}
