resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = local.tags
}

# Grant the Terraform executor rights to manage secrets
resource "azurerm_role_assignment" "kv_terraform_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant the App Service managed identity rights to read secrets
resource "azurerm_role_assignment" "kv_app_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

# Secrets
resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "JwtSecret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_terraform_officer]
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "AdminPassword"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_terraform_officer]
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "ConnectionStrings--DefaultConnection"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_terraform_officer]
}
