# =============================================================================
# Azure Infrastructure for Spring PetClinic
# Emergency Migration from AWS App Runner
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =============================================================================
# Resource Group
# =============================================================================

resource "azurerm_resource_group" "petclinic" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Application = "PetClinic"
    ManagedBy   = "Terraform"
    Migration   = "Emergency-AWS-to-Azure"
  }
}
