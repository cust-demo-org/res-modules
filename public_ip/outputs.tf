output "public_ips" {
  value       = module.public_ip
  description = "Map of public IP address keys to their AVM module objects (includes resource_id, public_ip_id, public_ip_address, name, and other module outputs)."
}
