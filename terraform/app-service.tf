resource "azurerm_service_plan" "main" {
  name                = "plan-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = local.tags
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on          = true
    websockets_enabled = true

    application_stack {
      docker_image_name   = "mamk95/devquiz:latest"
      docker_registry_url = "https://ghcr.io"
    }
  }

  app_settings = {
    "WEBSITES_PORT"                         = "8080"
    "ASPNETCORE_ENVIRONMENT"                = "Production"
    "JwtSecret"                             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.jwt_secret.versionless_id})"
    "AdminPassword"                         = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.admin_password.versionless_id})"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection_string.versionless_id})"
  }

  tags = local.tags
}

resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id
  https_only     = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on          = false
    websockets_enabled = true

    application_stack {
      docker_image_name   = "mamk95/devquiz:latest"
      docker_registry_url = "https://ghcr.io"
    }
  }

  app_settings = {
    "WEBSITES_PORT"                         = "8080"
    "ASPNETCORE_ENVIRONMENT"                = "Production"
    "JwtSecret"                             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.jwt_secret.versionless_id})"
    "AdminPassword"                         = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.admin_password.versionless_id})"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection_string.versionless_id})"
  }

  tags = local.tags
}

# Grant staging slot identity access to Key Vault
resource "azurerm_role_assignment" "kv_staging_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app_slot.staging.identity[0].principal_id
}
