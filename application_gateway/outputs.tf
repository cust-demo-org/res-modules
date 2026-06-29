output "application_gateways" {
  value       = module.application_gateway
  description = "Map of Application Gateway keys to their AVM module objects (includes resource_id, application_gateway_id, application_gateway_name, public_ip_id, new_public_ip_address, backend_address_pools, backend_http_settings, frontend_port, http_listeners, probes, request_routing_rules, ssl_certificates, waf_configuration, tags, and other module outputs)."
}
