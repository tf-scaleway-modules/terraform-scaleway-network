module "vpc" {
  source = "../../"

  organization_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  project_name    = "default"

  vpc_name   = "complete-example"
  vpc_region = "fr-par"
  vpc_zones  = ["fr-par-1", "fr-par-2"]

  vpc_enable_routing         = true
  vpc_enable_custom_routes   = true
  enable_gateway             = true
  enable_access_control_list = true
  access_control_list_rules = [
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
    },
    {
      protocol      = "TCP"
      src_port_low  = 0
      src_port_high = 0
      dst_port_low  = 443
      dst_port_high = 443
      source        = "0.0.0.0/0"
      destination   = "0.0.0.0/0"
      description   = "Allow HTTPS traffic from any source"
      action        = "accept"
    }
  ]

  network_private_networks = {
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
    }
  }

  enable_bastion            = true
  bastion_ssh_port          = 2222
  bastion_allowed_ip_ranges = ["0.0.0.0/0"]
  gateway_enable_masquerade = true
  gateway_enable_smtp       = false

  vpc_tags = ["example", "terraform", "complete"]
}
