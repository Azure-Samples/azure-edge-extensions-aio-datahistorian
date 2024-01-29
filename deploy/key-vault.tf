locals {
  key_vault_name          = var.key_vault_name != null ? var.key_vault_name : "kv-${var.name}"
  influxdb_admin_password = var.influxdb_admin_password != null ? var.influxdb_admin_password : random_password.influxdb_admin_password[0].result
  influxdb_admin_token    = var.influxdb_admin_token != null ? var.influxdb_admin_token : random_password.influxdb_admin_token[0].result
  grafana_admin_password  = var.grafana_admin_password != null ? var.grafana_admin_password : random_password.grafana_admin_password[0].result
}

data "azurerm_key_vault" "aio_kv" {
  count = var.should_create_secrets_in_key_vault ? 1 : 0

  name                = local.key_vault_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_key_vault_access_policy" "aio_kv_current_user" {
  count = var.should_grant_access_to_create_secrets ? 1 : 0

  key_vault_id = data.azurerm_key_vault.aio_kv[0].id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = ["Get", "List", "Set"]
}

resource "random_password" "influxdb_admin_password" {
  count = var.should_create_secrets_in_key_vault && var.influxdb_admin_password == null ? 1 : 0

  length  = 18
  special = true
}

resource "azurerm_key_vault_secret" "influxdb_admin_password" {
  count = var.should_create_secrets_in_key_vault ? 1 : 0

  name         = "influxdb-admin-password"
  key_vault_id = data.azurerm_key_vault.aio_kv[0].id
  value        = local.influxdb_admin_password

  depends_on = [azurerm_key_vault_access_policy.aio_kv_current_user]
}

resource "random_password" "influxdb_admin_token" {
  count = var.should_create_secrets_in_key_vault && var.influxdb_admin_token == null ? 1 : 0

  length  = 18
  special = true
}

resource "azurerm_key_vault_secret" "influxdb_admin_token" {
  count = var.should_create_secrets_in_key_vault ? 1 : 0

  name         = "influxdb-admin-token"
  key_vault_id = data.azurerm_key_vault.aio_kv[0].id
  value        = local.influxdb_admin_token

  depends_on = [azurerm_key_vault_access_policy.aio_kv_current_user]
}

resource "random_password" "grafana_admin_password" {
  count = var.should_create_secrets_in_key_vault && var.grafana_admin_password == null ? 1 : 0

  length  = 18
  special = true
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  count = var.should_create_secrets_in_key_vault ? 1 : 0

  name         = "grafana-admin-password"
  key_vault_id = data.azurerm_key_vault.aio_kv[0].id
  value        = local.grafana_admin_password

  depends_on = [azurerm_key_vault_access_policy.aio_kv_current_user]
}

resource "azurerm_key_vault_secret" "grafana_admin_user" {
  count = var.should_create_secrets_in_key_vault ? 1 : 0

  name         = "grafana-admin-user"
  key_vault_id = data.azurerm_key_vault.aio_kv[0].id
  value        = var.grafana_admin_user

  depends_on = [azurerm_key_vault_access_policy.aio_kv_current_user]
}