# ==============================================================================
# Local Values
# ==============================================================================
# This file contains computed local values used throughout the module.
# Extracting complex expressions here improves readability and maintainability.

locals {
  # Zones that get a gateway: none when the gateway is disabled
  gateway_zones = var.gateway == null ? toset([]) : toset(var.zones)

  # Zones without a caller-supplied flexible IP get a reserved one
  reserved_ip_zones = var.gateway == null ? toset([]) : setsubtract(local.gateway_zones, toset(keys(var.gateway.flexible_ip_ids)))

  # Network-zone pairs for creating IPAM IPs and gateway network attachments
  # Creates a map with keys like "web-fr-par-1", "app-fr-par-2", etc.
  # For N networks × Z zones, this creates N×Z entries
  network_zone_pairs = {
    for pair in setproduct(keys(var.private_networks), local.gateway_zones) :
    "${pair[0]}-${pair[1]}" => {
      network_key = pair[0]
      zone        = pair[1]
    }
  }

  # Port forwarding rules of the gateway
  pat_rules = var.gateway == null ? {} : var.gateway.pat_rules

  # One ACL per IP family that is set
  access_control_lists = {
    for family, acl in var.access_control_list == null ? {} : var.access_control_list : family => acl if acl != null
  }
}
