# =============================================================================
# Azure Database for MySQL Flexible Server
# =============================================================================

resource "azurerm_mysql_flexible_server" "petclinic" {
  name                   = var.db_server_name
  resource_group_name    = azurerm_resource_group.petclinic.name
  location               = azurerm_resource_group.petclinic.location
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  
  sku_name   = var.db_sku_name
  version    = var.db_mysql_version
  
  storage {
    size_gb = var.db_storage_size_gb
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  
  high_availability {
    mode = "Disabled" # Enable later for production
  }

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    Component   = "Database"
  }
}

# =============================================================================
# Database
# =============================================================================

resource "azurerm_mysql_flexible_database" "petclinic" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.petclinic.name
  server_name         = azurerm_mysql_flexible_server.petclinic.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# =============================================================================
# Firewall Rules
# =============================================================================

# Allow Azure services to access the database
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.petclinic.name
  server_name         = azurerm_mysql_flexible_server.petclinic.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Allow specified IP addresses (for migration and management)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_specified_ips" {
  count               = length(var.allowed_ip_addresses)
  name                = "AllowIP-${count.index}"
  resource_group_name = azurerm_resource_group.petclinic.name
  server_name         = azurerm_mysql_flexible_server.petclinic.name
  start_ip_address    = split("/", var.allowed_ip_addresses[count.index])[0]
  end_ip_address      = split("/", var.allowed_ip_addresses[count.index])[0]
}

# =============================================================================
# Database Configuration
# =============================================================================

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.petclinic.name
  server_name         = azurerm_mysql_flexible_server.petclinic.name
  value               = "OFF" # Allow non-SSL initially for easier migration, enable later
}
