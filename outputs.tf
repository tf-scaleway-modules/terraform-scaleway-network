# ==============================================================================
# VPC Core Outputs
# ==============================================================================

output "vpc_id" {
  description = "VPC resource identifier"
  value       = scaleway_vpc.this.id
}

# ==============================================================================
# Access Control List Outputs
# ==============================================================================

output "access_control_list_ids" {
  description = "VPC Access Control List IDs by IP family (ipv4, ipv6); empty if no ACL is created"
  value = {
    for k, v in scaleway_vpc_acl.this : k => v.id
  }
}

# ==============================================================================
# Private Network Outputs
# ==============================================================================

output "private_network_ids" {
  description = "Private network IDs by network key"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => v.id
  }
}

output "private_network_ipv4_cidrs" {
  description = "First IPv4 CIDR block by network key (null if the network has none)"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => try(v.ipv4_subnet[0].subnet, null)
  }
}

output "private_network_ipv6_cidrs" {
  description = "IPv6 CIDR blocks by network key (empty list if the network has none)"
  value = {
    for k, v in scaleway_vpc_private_network.this : k => v.ipv6_subnets[*].subnet
  }
}

# ==============================================================================
# Route Outputs
# ==============================================================================

output "route_ids" {
  description = "VPC route IDs by route key"
  value = {
    for k, v in scaleway_vpc_route.this : k => v.id
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
  description = "IDs of the flexible IPs reserved by the module, by zone (existing IPs from gateway.flexible_ip_ids are not listed)"
  value = {
    for k, v in scaleway_vpc_public_gateway_ip.this : k => v.id
  }
}

output "gateway_flexible_ip_addresses" {
  description = "Public IP addresses reserved by the module, by zone (existing IPs from gateway.flexible_ip_ids are not listed)"
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

output "pat_rule_ids" {
  description = "Port forwarding rule IDs by rule key"
  value = {
    for k, v in scaleway_vpc_public_gateway_pat_rule.this : k => v.id
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
