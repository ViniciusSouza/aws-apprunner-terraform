# =============================================================================
# Azure Infrastructure Variables
# =============================================================================

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-petclinic-prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# =============================================================================
# Database Variables
# =============================================================================

variable "db_server_name" {
  description = "Name of the MySQL Flexible Server (must be globally unique)"
  type        = string
  default     = "petclinic-mysql-prod"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "petclinic"
}

variable "db_admin_username" {
  description = "Database administrator username"
  type        = string
  default     = "adminuser"
}

variable "db_admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "Database SKU name (B_Standard_B1ms for burstable, GP_Standard_D2s_v3 for production)"
  type        = string
  default     = "B_Standard_B1ms" # Start cheap, scale up if needed
}

variable "db_storage_size_gb" {
  description = "Database storage size in GB"
  type        = number
  default     = 32
}

variable "db_mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.21"
}

# =============================================================================
# App Service Variables
# =============================================================================

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "plan-petclinic-prod"
}

variable "app_service_name" {
  description = "Name of the App Service (must be globally unique)"
  type        = string
  default     = "petclinic-prod"
}

variable "app_service_sku" {
  description = "App Service Plan SKU (B1, P1v2, P2v2, etc.)"
  type        = string
  default     = "P1v2" # Production tier, can downgrade to B1 for testing
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "ghcr.io/viniciusouza/petclinic:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

# =============================================================================
# Monitoring Variables
# =============================================================================

variable "app_insights_name" {
  description = "Name of the Application Insights instance"
  type        = string
  default     = "petclinic-insights-prod"
}

# =============================================================================
# Network Variables (Optional - for future VNet integration)
# =============================================================================

variable "enable_vnet_integration" {
  description = "Enable VNet integration for App Service"
  type        = bool
  default     = false # Disable for fast-track, enable later
}

variable "allowed_ip_addresses" {
  description = "IP addresses allowed to access the database (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open initially, restrict later
}
