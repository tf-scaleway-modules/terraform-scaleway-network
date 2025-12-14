output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "network_ids" {
  description = "Map of all network IDs"
  value       = module.vpc.network_private_network_ids
}

output "gateway_ids" {
  description = "Map of gateway IDs by zone"
  value       = module.vpc.gateway_ids
}

output "gateway_ips" {
  description = "Map of gateway public IPs by zone"
  value       = module.vpc.gateway_flexible_ip_addresses
}

output "acl_id" {
  description = "ID of the Access Control List"
  value       = module.vpc.access_control_list_id
}
