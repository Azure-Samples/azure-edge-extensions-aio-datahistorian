variable "name" {
  description = "The unique primary name used when naming resources. (ex. 'test' makes 'rg-test' resource group)"
  type        = string
  nullable    = false
  validation {
    condition     = var.name != "sample-aio" && length(var.name) < 15 && can(regex("^[a-z0-9][a-z0-9-]{1,60}[a-z0-9]$", var.name))
    error_message = "Please update 'name' to a short, unique name, that only has lowercase letters, numbers, '-' hyphens."
  }
}

variable "location" {
  type    = string
  default = "westus3"
}

variable "resource_group_name" {
  description = "(Optional) The resource group name where the Azure Arc Cluster resource is located. (Otherwise, 'rg-<var.name>')"
  type        = string
  default     = null
}

variable "arc_cluster_name" {
  description = "(Optional) the Arc Cluster resource name. (Otherwise, 'arc-<var.name>')"
  type        = string
  default     = null
}

variable "custom_locations_name" {
  description = "(Optional) the Custom Locations resource name. (Otherwise, 'cl-<var.name>-aio')"
  type        = string
  default     = null
}

variable "aio_cluster_namespace" {
  description = "(Optional) The namespace in the Arc Cluster where data historian resources will be installed. (Otherwise, 'aio')"
  type        = string
  default     = "aio"
}

variable "datahistorian_targets_main_version" {
  description = "(Optional) The version of the Targets that's deployed using AIO. (Otherwise, '1.0.0')"
  type        = string
  default     = "1.0.0"
}

variable "echo_cluster_namespace" {
  description = "(Optional) The namespace in the Arc Cluster where the HTTP echo service will be installed. (Otherwise, 'echo')"
  type        = string
  default     = "echo"
}

variable "echo_targets_main_version" {
  description = "(Optional) The version of the Targets for the echo service that's deployed using AIO. (Otherwise, '1.0.0')"
  type        = string
  default     = "1.0.0"
}

variable "influxdb_admin_user" {
  description = "(Optional) The admin user name for the default bucket. (Otherwise, 'admin')"
  type        = string
  default     = "admin"
}

variable "influxdb_admin_password" {
  description = "(Optional) The admin password for the default bucket. (Otherwise, generated and stored in key vault if enabled)"
  type        = string
  default     = null
}

variable "influxdb_admin_token" {
  description = "(Optional) The admin token for the default bucket. (Otherwise, generated and stored in key vault if enabled)"
  type        = string
  default     = null
}

variable "influxdb_admin_organization" {
  description = "(Optional) The organization for that contains the default bucket. (Otherwise, 'datahistorian')"
  type        = string
  default     = "datahistorian"
}

variable "influxdb_admin_bucket" {
  description = "(Optional) The bucket for the admin organization. (Otherwise, 'default')"
  type        = string
  default     = "default"
}

variable "influxdb_admin_bucket_retention_policy" {
  description = "(Optional) The retention policy for the admin bucket. (Otherwise, '1w' -> one week, set to '0s' for infinite)"
  type        = string
  default     = "1w"
}

variable "influxdb_persistence_should_use_existing_pvc" {
  description = "(Optional) Use an existing PVC instead of creating a new one. (Otherwise, 'false')"
  type        = bool
  default     = false
}

variable "influxdb_persistence_pvc_name" {
  description = "(Optional) The name of the existing PVC to use for persistence. (Otherwise, null)"
  type        = string
  default     = null
}

variable "influxdb_persistence_pvc_storage_class" {
  description = "(Optional) The PVC storage class name to use for persistence. (Otherwise, null -> '-' disables dynamic provisioning)"
  type        = string
  default     = null
}

variable "influxdb_persistence_size" {
  description = "(Optional) The maximum amount of storage space to use for persisting data. (Otherwise, '5Gi')"
  type        = string
  default     = "5Gi"
}

variable "should_create_secrets_in_key_vault" {
  description = "(Optional) Enables creating secrets in Azure Key Vault for InfluxDB. (Otherwise, 'true')"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "(Optional) The Azure Key Vault name used to store secrets for AIO. (Otherwise, 'kv-<var.name>')"
  type        = string
  default     = null
}

variable "should_grant_access_to_create_secrets" {
  description = "(Optional) Grants the current user access to create secrets in the Azure Key Vault for AIO. (Otherwise, 'false' -> assuming the current user already has access to create secrets)"
  type        = bool
  default     = false
}