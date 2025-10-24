# =============================================================================
# Azure Infrastructure Configuration
# Emergency Azure Migration - Spring PetClinic
# =============================================================================

# Resource Group
resource_group_name = "rg-petclinic-emergency"
location            = "eastus"
environment         = "prod"

# Database
db_server_name     = "petclinic-mysql-emergency-vjs" # Globally unique
db_name            = "petclinic"
db_admin_username  = "adminuser"
# db_admin_password will be set via environment variable TF_VAR_db_admin_password
db_sku_name        = "B_Standard_B1ms" # Burstable tier for cost savings
db_storage_size_gb = 32
db_mysql_version   = "8.0.21"

# App Service
app_service_plan_name = "plan-petclinic-emergency"
app_service_name      = "petclinic-emergency-vjs" # Globally unique
app_service_sku       = "B1" # Start with B1 for testing, upgrade to P1v2 if needed
docker_image          = "ghcr.io/viniciusouza/petclinic:latest"
container_port        = 80

# Monitoring
app_insights_name = "petclinic-insights-emergency"

# Network
allowed_ip_addresses = [] # Empty for now, will allow all Azure services
