output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "network_ids" {
  description = "Map of all network IDs"
  value       = module.vpc.private_network_ids
}

output "gateway_ids" {
  description = "Map of gateway IDs by zone"
  value       = module.vpc.gateway_ids
}

output "gateway_ips" {
  description = "Map of reserved gateway public IPs by zone"
  value       = module.vpc.gateway_flexible_ip_addresses
}

output "acl_ids" {
  description = "IDs of the Access Control Lists by IP family"
  value       = module.vpc.access_control_list_ids
}

output "route_ids" {
  description = "IDs of the custom routes"
  value       = module.vpc.route_ids
}

output "pat_rule_ids" {
  description = "IDs of the port forwarding rules"
  value       = module.vpc.pat_rule_ids
}
