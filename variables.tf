# ==============================================================================
# VPC Core Configuration
# ==============================================================================
variable "organization_id" {
  description = "Organization ID for VPC resources"
  type        = string
}

variable "project_name" {
  description = "Project name for VPC resources"
  type        = string
}

variable "vpc_region" {
  description = "Region where VPC resources will be created (defaults to provider configuration)"
  type        = string
  default     = null
}

variable "vpc_zones" {
  description = "Availability zones for gateway deployment (must belong to vpc_region if both specified)"
  type        = list(string)
  default     = []

  validation {
    condition     = (var.vpc_region == null && length(var.vpc_zones) == 0) || (var.vpc_region != null && length(var.vpc_zones) == 0) || (var.vpc_region == null && length(var.vpc_zones) > 0 && length(distinct([for zone in var.vpc_zones : substr(zone, 0, length(zone) - 2)])) <= 1) || (var.vpc_region != null && length(var.vpc_zones) > 0 && alltrue([for zone in var.vpc_zones : startswith(zone, var.vpc_region)]))
    error_message = "When both region and zones are specified, all zones must belong to the specified region. When only zones are specified, all zones must belong to the same region."
  }
}

variable "vpc_name" {
  description = "Name prefix for the VPC and associated resources"
  type        = string
}

variable "vpc_enable_routing" {
  description = "Enable routing between private networks (cannot be disabled once enabled)"
  type        = bool
  default     = true
}

variable "vpc_enable_custom_routes" {
  description = "Enable custom route propagation between private networks"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Tags to apply to all VPC resources"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Private Networks Configuration
# ==============================================================================

variable "network_private_networks" {
  description = "Private networks to create with optional names, subnets, and tags"
  type = map(object({
    name        = optional(string)           # Network name (defaults to auto-generated)
    ipv4_subnet = optional(string)           # IPv4 CIDR (defaults to auto-assigned /22)
    ipv6_subnet = optional(string)           # IPv6 CIDR (defaults to auto-assigned /64)
    tags        = optional(list(string), []) # Network-specific tags
  }))
  default = {
    default = {
      name        = null
      ipv4_subnet = null
      ipv6_subnet = null
      tags        = []
    }
  }
}

# ==============================================================================
# Gateway Configuration
# ==============================================================================

variable "enable_gateway" {
  description = "Create public gateways for internet connectivity"
  type        = bool
  default     = true
}

variable "gateway_type" {
  description = "Gateway instance type: VPC-GW-S (small) or VPC-GW-M (medium)"
  type        = string
  default     = "VPC-GW-S"

  validation {
    condition     = contains(["VPC-GW-S", "VPC-GW-M"], var.gateway_type)
    error_message = "Gateway type must be either 'VPC-GW-S' or 'VPC-GW-M'."
  }
}

variable "gateway_reserve_flexible_ip" {
  description = "Reserve new flexible IP addresses for gateways"
  type        = bool
  default     = true
}

variable "gateway_existing_flexible_ip_id" {
  description = "Existing flexible IP ID to attach (overrides gateway_reserve_flexible_ip)"
  type        = string
  default     = null
}

variable "gateway_enable_masquerade" {
  description = "Enable NAT masquerade for outbound internet access"
  type        = bool
  default     = true
}

variable "gateway_enable_smtp" {
  description = "Enable SMTP (port 25) for email delivery"
  type        = bool
  default     = false
}

variable "gateway_refresh_ssh_keys" {
  description = "Trigger SSH key refresh on gateways (change value to trigger)"
  type        = string
  default     = null
}

# ==============================================================================
# Access Control List Configuration
# ==============================================================================

variable "enable_access_control_list" {
  description = "Create VPC Access Control List for traffic filtering"
  type        = bool
  default     = false
}

variable "access_control_list_is_ipv6" {
  description = "Apply ACL rules to IPv6 traffic instead of IPv4"
  type        = bool
  default     = false
}

variable "access_control_list_default_policy" {
  description = "Default action when no ACL rules match: accept or drop"
  type        = string
  default     = "accept"

  validation {
    condition     = contains(["accept", "drop"], var.access_control_list_default_policy)
    error_message = "ACL default policy must be either 'accept' or 'drop'."
  }
}

variable "access_control_list_rules" {
  description = "ACL rules for traffic filtering (protocol, ports, source/destination, action)"
  type = list(object({
    protocol      = string # Protocol: ANY, TCP, UDP, or ICMP
    src_port_low  = number
    src_port_high = number
    dst_port_low  = number
    dst_port_high = number
    source        = string
    destination   = string
    description   = string
    action        = string
  }))
  default = [
    {
      protocol      = "TCP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 80
      dst_port_high = 80
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "Allow HTTP traffic from any source"
      action        = "accept"
    }
  ]
}

# ==============================================================================
# Bastion Configuration
# ==============================================================================

variable "enable_bastion" {
  description = "Enable SSH bastion on public gateways for secure access"
  type        = bool
  default     = false
}

variable "bastion_ssh_port" {
  description = "SSH port for bastion access (1-65535)"
  type        = number
  default     = 61000

  validation {
    condition     = var.bastion_ssh_port >= 1 && var.bastion_ssh_port <= 65535
    error_message = "Bastion SSH port must be between 1 and 65535."
  }
}

variable "bastion_allowed_ip_ranges" {
  description = "CIDR ranges allowed to access SSH bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
