resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  tags = local.tags
}

resource "azurerm_mssql_database" "main" {
  name      = var.project_name
  server_id = azurerm_mssql_server.main.id

  # Serverless Gen5 with auto-pause
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32

  tags = local.tags
}

# Allow only App Service outbound IPs to access the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_app_service" {
  for_each         = toset(azurerm_linux_web_app.main.outbound_ip_address_list)
  name             = "AllowAppService-${replace(each.value, ".", "-")}"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value
  end_ip_address   = each.value
}
