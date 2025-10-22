# =============================================================================
# Application Insights (Azure Monitor)
# =============================================================================

resource "azurerm_log_analytics_workspace" "petclinic" {
  name                = "law-${var.app_service_name}"
  resource_group_name = azurerm_resource_group.petclinic.name
  location            = azurerm_resource_group.petclinic.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    Component   = "Monitoring"
  }
}

resource "azurerm_application_insights" "petclinic" {
  name                = var.app_insights_name
  resource_group_name = azurerm_resource_group.petclinic.name
  location            = azurerm_resource_group.petclinic.location
  workspace_id        = azurerm_log_analytics_workspace.petclinic.id
  application_type    = "java"

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    Component   = "Monitoring"
  }
}

# =============================================================================
# Alerts
# =============================================================================

# Alert when app is down
resource "azurerm_monitor_metric_alert" "app_down" {
  name                = "alert-${var.app_service_name}-down"
  resource_group_name = azurerm_resource_group.petclinic.name
  scopes              = [azurerm_linux_web_app.petclinic.id]
  description         = "Alert when PetClinic application is down"
  severity            = 0 # Critical

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HealthCheckStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  window_size        = "PT5M"
  frequency          = "PT1M"
  auto_mitigate      = true

  tags = {
    Environment = var.environment
    Application = "PetClinic"
  }
}

# Alert for high response time
resource "azurerm_monitor_metric_alert" "high_response_time" {
  name                = "alert-${var.app_service_name}-slow-response"
  resource_group_name = azurerm_resource_group.petclinic.name
  scopes              = [azurerm_linux_web_app.petclinic.id]
  description         = "Alert when response time is high"
  severity            = 2 # Warning

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5 # 5 seconds
  }

  window_size        = "PT5M"
  frequency          = "PT5M"
  auto_mitigate      = true

  tags = {
    Environment = var.environment
    Application = "PetClinic"
  }
}

# Alert for high error rate
resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "alert-${var.app_service_name}-errors"
  resource_group_name = azurerm_resource_group.petclinic.name
  scopes              = [azurerm_linux_web_app.petclinic.id]
  description         = "Alert when HTTP 5xx error rate is high"
  severity            = 1 # Error

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  window_size        = "PT5M"
  frequency          = "PT1M"
  auto_mitigate      = true

  tags = {
    Environment = var.environment
    Application = "PetClinic"
  }
}
