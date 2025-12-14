output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "network_id" {
  description = "ID of the private network"
  value       = module.vpc.network_private_network_ids["main"]
}

output "gateway_ip" {
  description = "Public IP of the gateway"
  value       = module.vpc.gateway_flexible_ip_addresses["fr-par-1"]
}

output "network_ipv4_cidr" {
  description = "IPv4 CIDR of the network"
  value       = module.vpc.network_ipv4_cidrs["main"]
}
