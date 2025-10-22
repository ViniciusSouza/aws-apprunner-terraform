# =============================================================================
# Azure App Service Plan
# =============================================================================

resource "azurerm_service_plan" "petclinic" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.petclinic.name
  location            = azurerm_resource_group.petclinic.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    Component   = "Compute"
  }
}

# =============================================================================
# Azure App Service (Web App for Containers)
# =============================================================================

resource "azurerm_linux_web_app" "petclinic" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.petclinic.name
  location            = azurerm_resource_group.petclinic.location
  service_plan_id     = azurerm_service_plan.petclinic.id

  https_only = true

  site_config {
    always_on = true
    
    application_stack {
      docker_image_name   = var.docker_image
      docker_registry_url = "https://ghcr.io"
    }

    health_check_path = "/actuator/health"
    
    # CORS configuration (if needed for future API access)
    cors {
      allowed_origins = ["*"] # Restrict in production
    }
  }

  app_settings = {
    # Container configuration
    WEBSITES_PORT                           = var.container_port
    DOCKER_REGISTRY_SERVER_URL              = "https://ghcr.io"
    DOCKER_ENABLE_CI                        = "true"
    
    # Spring Boot configuration
    SPRING_PROFILES_ACTIVE                  = "mysql"
    
    # Database configuration
    MYSQL_URL                               = "jdbc:mysql://${azurerm_mysql_flexible_server.petclinic.fqdn}/${var.db_name}?useSSL=true&requireSSL=false&serverTimezone=UTC"
    MYSQL_USER                              = var.db_admin_username
    MYSQL_PASS                              = var.db_admin_password
    
    # Application Insights (added after insights resource is created)
    APPLICATIONINSIGHTS_CONNECTION_STRING   = azurerm_application_insights.petclinic.connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY          = azurerm_application_insights.petclinic.instrumentation_key
    
    # Java configuration
    JAVA_OPTS                               = "-Xms512m -Xmx1024m"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
    
    application_logs {
      file_system_level = "Information"
    }
  }

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    Component   = "WebApp"
  }

  depends_on = [
    azurerm_mysql_flexible_database.petclinic
  ]
}

# =============================================================================
# Container Registry Webhook (Optional - for auto-deploy on image push)
# =============================================================================

# Note: This would require Azure Container Registry
# For now, using GitHub Container Registry with manual deployment
# Can add webhook configuration later for automated deployments
