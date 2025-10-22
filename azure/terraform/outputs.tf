# =============================================================================
# Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.petclinic.name
}

output "app_service_url" {
  description = "URL of the deployed application"
  value       = "https://${azurerm_linux_web_app.petclinic.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.petclinic.name
}

output "database_fqdn" {
  description = "Fully qualified domain name of the MySQL server"
  value       = azurerm_mysql_flexible_server.petclinic.fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_mysql_flexible_database.petclinic.name
}

output "database_connection_string" {
  description = "Database connection string (without password)"
  value       = "jdbc:mysql://${azurerm_mysql_flexible_server.petclinic.fqdn}/${var.db_name}"
  sensitive   = false
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.petclinic.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.petclinic.connection_string
  sensitive   = true
}

# =============================================================================
# Quick Reference Commands
# =============================================================================

output "useful_commands" {
  description = "Useful Azure CLI commands"
  value = <<-EOT
  
  # View application logs
  az webapp log tail --resource-group ${azurerm_resource_group.petclinic.name} --name ${azurerm_linux_web_app.petclinic.name}
  
  # Restart application
  az webapp restart --resource-group ${azurerm_resource_group.petclinic.name} --name ${azurerm_linux_web_app.petclinic.name}
  
  # Connect to database
  mysql -h ${azurerm_mysql_flexible_server.petclinic.fqdn} -u ${var.db_admin_username} -p ${var.db_name}
  
  # View Application Insights
  az monitor app-insights component show --app ${azurerm_application_insights.petclinic.name} --resource-group ${azurerm_resource_group.petclinic.name}
  
  # Update container image
  az webapp config container set --resource-group ${azurerm_resource_group.petclinic.name} --name ${azurerm_linux_web_app.petclinic.name} --docker-custom-image-name ${var.docker_image}
  
  EOT
}
