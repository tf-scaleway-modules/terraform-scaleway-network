# ==============================================================================
# VPC Core Configuration
# ==============================================================================
variable "name" {
  description = "Name of the VPC; also the prefix of every public gateway (<name>-<zone>) and of unnamed private networks (<name>-<key>)"
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "project_id" {
  description = "Project UUID that owns the resources (null uses the provider's default project)"
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "project_id must be a project UUID or null."
  }
}

variable "region" {
  description = "Region where the regional resources are created (null uses the provider's region)"
  type        = string
  default     = null
}

variable "zones" {
  description = "Availability zones that each get a public gateway (must belong to region if both are specified)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for zone in var.zones : zone != ""])
    error_message = "zones must not contain empty strings."
  }

  validation {
    condition     = length(var.zones) == 0 || (var.region != null ? alltrue([for zone in var.zones : startswith(zone, var.region)]) : length(distinct([for zone in var.zones : substr(zone, 0, length(zone) - 2)])) <= 1)
    error_message = "When both region and zones are specified, all zones must belong to the specified region. When only zones are specified, all zones must belong to the same region."
  }
}

variable "tags" {
  description = "Tags applied to the VPC, private networks, gateways, gateway IPs, IPAM IPs and routes"
  type        = list(string)
  default     = []
}

variable "enable_transitivity" {
  description = "Allow packets from peered VPCs (VPC connectors) to transit through this VPC"
  type        = bool
  default     = false
}

# ==============================================================================
# Private Networks Configuration
# ==============================================================================

variable "private_networks" {
  description = "Private networks keyed by name; a network without name is named <name>-<key>; subnets are given in network address form (for example 10.0.1.0/24)"
  type = map(object({
    name                             = optional(string)           # Network name (defaults to <name>-<key>)
    ipv4_subnet                      = optional(string)           # IPv4 CIDR (defaults to auto-assigned /22)
    ipv6_subnet                      = optional(string)           # IPv6 CIDR (defaults to auto-assigned /64)
    tags                             = optional(list(string), []) # Network-specific tags, merged with tags
    enable_default_route_propagation = optional(bool)             # Default route propagation (null keeps the provider default)
  }))
  default = { default = {} }

  validation {
    condition = alltrue([
      for network in values(var.private_networks) :
      (network.ipv4_subnet == null || (can(cidrnetmask(network.ipv4_subnet)))) &&
      (network.ipv6_subnet == null || (strcontains(network.ipv6_subnet, ":") && can(cidrhost(network.ipv6_subnet, 0))))
    ])
    error_message = "ipv4_subnet and ipv6_subnet must be valid CIDR blocks."
  }
}

# ==============================================================================
# Gateway Configuration
# ==============================================================================

variable "gateway" {
  description = "Public gateway settings, one gateway per zone of zones (null disables the gateways). type: VPC-GW-S/M/L/XL; flexible_ip_ids: zone to existing flexible IP ID (other zones get a reserved IP); refresh_ssh_keys: change the value to refresh SSH keys; bastion: SSH bastion (allowed_ip_ranges required); pat_rules: port forwarding rules keyed by name"
  type = object({
    type              = optional(string, "VPC-GW-S")
    flexible_ip_ids   = optional(map(string), {})
    enable_masquerade = optional(bool, true)
    enable_smtp       = optional(bool, false)
    refresh_ssh_keys  = optional(string)
    bastion = optional(object({
      port              = optional(number, 61000)
      allowed_ip_ranges = list(string)
    }))
    pat_rules = optional(map(object({
      zone         = string
      public_port  = number
      private_ip   = string
      private_port = number
      protocol     = optional(string, "both")
    })), {})
  })
  default = {}

  validation {
    condition     = alltrue([for g in var.gateway[*] : contains(["VPC-GW-S", "VPC-GW-M", "VPC-GW-L", "VPC-GW-XL"], g.type)])
    error_message = "Gateway type must be one of 'VPC-GW-S', 'VPC-GW-M', 'VPC-GW-L' or 'VPC-GW-XL'."
  }

  validation {
    condition     = alltrue([for g in var.gateway[*] : g.bastion == null ? true : g.bastion.port >= 1 && g.bastion.port <= 65535])
    error_message = "Bastion SSH port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for g in var.gateway[*] :
      g.bastion == null ? true : length(g.bastion.allowed_ip_ranges) > 0 && alltrue([for cidr in g.bastion.allowed_ip_ranges : can(cidrhost(cidr, 0))])
    ])
    error_message = "bastion.allowed_ip_ranges must hold at least one valid CIDR block."
  }

  validation {
    condition = alltrue([
      for g in var.gateway[*] :
      alltrue([for zone in keys(g.flexible_ip_ids) : contains(var.zones, zone)]) && alltrue([for rule in values(g.pat_rules) : contains(var.zones, rule.zone)])
    ])
    error_message = "gateway.flexible_ip_ids keys, pat_rules zones and the bastion must refer to zones listed in zones."
  }

  validation {
    condition = alltrue([
      for g in var.gateway[*] :
      alltrue([
        for rule in values(g.pat_rules) :
        contains(["both", "tcp", "udp"], rule.protocol) && rule.public_port >= 1 && rule.public_port <= 65535 && rule.private_port >= 1 && rule.private_port <= 65535
      ])
    ])
    error_message = "pat_rules protocol must be 'both', 'tcp' or 'udp', and ports must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for g in var.gateway[*] :
      length(distinct([for rule in values(g.pat_rules) : "${rule.zone}:${rule.public_port}"])) == length(g.pat_rules)
    ])
    error_message = "pat_rules must not reuse a public_port within a zone."
  }
}

# ==============================================================================
# Access Control List Configuration
# ==============================================================================

variable "access_control_list" {
  description = "VPC access control list, one ACL per IP family set (null disables it); each family has a default_policy (accept or drop) and ordered rules (protocol: ANY, TCP, UDP or ICMP; action: accept or drop; ports 0-65535, 0 meaning any); CIDRs are given in network address form"
  type = object({
    ipv4 = optional(object({
      default_policy = optional(string, "accept")
      rules = optional(list(object({
        source        = string
        destination   = string
        action        = string
        protocol      = optional(string, "ANY")
        src_port_low  = optional(number, 0)
        src_port_high = optional(number, 0)
        dst_port_low  = optional(number, 0)
        dst_port_high = optional(number, 0)
        description   = optional(string)
      })), [])
    }))
    ipv6 = optional(object({
      default_policy = optional(string, "accept")
      rules = optional(list(object({
        source        = string
        destination   = string
        action        = string
        protocol      = optional(string, "ANY")
        src_port_low  = optional(number, 0)
        src_port_high = optional(number, 0)
        dst_port_low  = optional(number, 0)
        dst_port_high = optional(number, 0)
        description   = optional(string)
      })), [])
    }))
  })
  default = null

  validation {
    condition = alltrue([
      for acl in var.access_control_list[*] :
      alltrue([for family in [acl.ipv4, acl.ipv6] : contains(["accept", "drop"], family.default_policy) if family != null])
    ])
    error_message = "ACL default policy must be either 'accept' or 'drop'."
  }

  validation {
    condition = alltrue([
      for acl in var.access_control_list[*] :
      alltrue(flatten([for family in [acl.ipv4, acl.ipv6] : [for rule in family.rules : contains(["ANY", "TCP", "UDP", "ICMP"], rule.protocol) && contains(["accept", "drop"], rule.action)] if family != null]))
    ])
    error_message = "ACL rule protocol must be one of 'ANY', 'TCP', 'UDP' or 'ICMP' and action must be 'accept' or 'drop'."
  }

  validation {
    condition = alltrue([
      for acl in var.access_control_list[*] :
      alltrue(flatten([
        for family in [acl.ipv4, acl.ipv6] : [
          for rule in family.rules :
          rule.src_port_low >= 0 && rule.src_port_high <= 65535 && rule.src_port_low <= rule.src_port_high && rule.dst_port_low >= 0 && rule.dst_port_high <= 65535 && rule.dst_port_low <= rule.dst_port_high
        ] if family != null
      ]))
    ])
    error_message = "ACL rule ports must be between 0 and 65535 and low must not exceed high."
  }

  validation {
    condition = alltrue([
      for acl in var.access_control_list[*] :
      alltrue(flatten([for family in [acl.ipv4, acl.ipv6] : [for rule in family.rules : can(cidrhost(rule.source, 0)) && can(cidrhost(rule.destination, 0))] if family != null]))
    ])
    error_message = "ACL rule source and destination must be valid CIDR blocks."
  }
}

# ==============================================================================
# Routes Configuration
# ==============================================================================

variable "routes" {
  description = "Custom VPC routes keyed by name; each sets exactly one next hop: nexthop_private_network (a key of private_networks), nexthop_resource_id or nexthop_vpc_connector_id; destination is given in network address form"
  type = map(object({
    destination              = string
    description              = optional(string)
    tags                     = optional(list(string), [])
    nexthop_private_network  = optional(string)
    nexthop_resource_id      = optional(string)
    nexthop_vpc_connector_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for route in values(var.routes) :
      length([for hop in [route.nexthop_private_network, route.nexthop_resource_id, route.nexthop_vpc_connector_id] : hop if hop != null]) == 1
    ])
    error_message = "Each route must set exactly one of nexthop_private_network, nexthop_resource_id or nexthop_vpc_connector_id."
  }

  validation {
    condition     = alltrue([for route in values(var.routes) : can(cidrhost(route.destination, 0))])
    error_message = "Route destinations must be valid CIDR blocks."
  }

  validation {
    condition     = alltrue([for route in values(var.routes) : route.nexthop_private_network == null ? true : contains(keys(var.private_networks), route.nexthop_private_network)])
    error_message = "nexthop_private_network must be a key of private_networks."
  }
}
