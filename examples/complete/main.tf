variable "existing_flexible_ip_ids" {
  description = "Existing flexible IP IDs by zone; zones not listed get a reserved IP"
  type        = map(string)
  default     = {}
}

module "vpc" {
  source = "../../"

  # project_id = "00000000-0000-0000-0000-000000000000" # defaults to the provider project
  name   = "complete-example"
  region = "fr-par"
  zones  = ["fr-par-1", "fr-par-2"]
  tags   = ["example", "terraform", "complete"]

  access_control_list = {
    ipv4 = {
      rules = [
        {
          protocol      = "TCP"
          dst_port_low  = 80
          dst_port_high = 80
          source        = "0.0.0.0/0"
          destination   = "0.0.0.0/0"
          description   = "Allow HTTP traffic from any source"
          action        = "accept"
        },
        {
          protocol      = "TCP"
          dst_port_low  = 443
          dst_port_high = 443
          source        = "0.0.0.0/0"
          destination   = "0.0.0.0/0"
          description   = "Allow HTTPS traffic from any source"
          action        = "accept"
        },
        {
          protocol    = "ICMP"
          source      = "0.0.0.0/0"
          destination = "0.0.0.0/0"
          description = "Drop ICMP traffic from any source"
          action      = "drop"
        }
      ]
    }
    ipv6 = {
      default_policy = "drop"
      rules = [
        {
          protocol      = "TCP"
          dst_port_low  = 443
          dst_port_high = 443
          source        = "::/0"
          destination   = "::/0"
          description   = "Allow HTTPS over IPv6"
          action        = "accept"
        }
      ]
    }
  }

  private_networks = {
    web = {
      name        = "web-network"
      ipv4_subnet = "10.0.1.0/24"
      tags        = ["web", "public"]
    }
    app = {
      name        = "app-network"
      ipv4_subnet = "10.0.2.0/24"
      ipv6_subnet = "2001:db8::/64"
      tags        = ["app", "internal"]

      enable_default_route_propagation = true
    }
  }

  routes = {
    appliance = {
      destination             = "192.168.0.0/16"
      description             = "Corporate ranges through the app network"
      nexthop_private_network = "app"
    }
  }

  gateway = {
    flexible_ip_ids = var.existing_flexible_ip_ids
    bastion = {
      port              = 2222
      allowed_ip_ranges = ["203.0.113.0/24"]
    }
    pat_rules = {
      ssh = {
        zone         = "fr-par-1"
        public_port  = 2223
        private_ip   = "10.0.1.10"
        private_port = 22
      }
    }
  }
}
