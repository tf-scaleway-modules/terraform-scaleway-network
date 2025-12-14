# ==============================================================================
# Local Values
# ==============================================================================
# This file contains computed local values used throughout the module.
# Extracting complex expressions here improves readability and maintainability.

locals {
  # Network-zone pairs for creating IPAM IPs and gateway network attachments
  # Creates a map with keys like "web-fr-par-1", "app-fr-par-2", etc.
  # For N networks × Z zones, this creates N×Z entries
  network_zone_pairs = var.enable_gateway ? {
    for pair in setproduct(keys(var.network_private_networks), compact(var.vpc_zones)) :
    "${pair[0]}-${pair[1]}" => {
      network_key = pair[0]
      zone        = pair[1]
    }
  } : {}

  # Set of zones for gateway resource creation
  # Compacts the zones list to remove empty strings
  gateway_zones = var.enable_gateway ? toset(compact(var.vpc_zones)) : []

  # Set of zones for gateway IP reservation
  # Only creates IPs when both gateway is enabled AND IP reservation is requested
  gateway_ip_zones = var.enable_gateway && var.gateway_reserve_flexible_ip ? toset(compact(var.vpc_zones)) : []

  # Tags to apply to all VPC resources
  # Ensures consistent tagging across all created resources
  common_tags = var.vpc_tags
}
