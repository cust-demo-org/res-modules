output "cosmos_db" {
  value       = module.cosmos_db
  description = "Map of Cosmos DB account keys to their AVM module objects. Each object includes resource_id, name, endpoint, and the module's other outputs (sql_databases, mongo_databases, cosmosdb_keys, connection strings, etc.)."
}
