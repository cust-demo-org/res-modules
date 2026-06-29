output "web_application_firewall_policies" {
  value       = module.web_application_firewall_policy
  description = "Map of WAF policy keys to their AVM module objects (includes resource_id, name, http_listener_ids, path_based_rule_ids, and other module outputs)."
}
