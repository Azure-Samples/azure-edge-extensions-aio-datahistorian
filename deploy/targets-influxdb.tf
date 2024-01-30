locals {
  volume_mounts = yamldecode(file("./manifests/volumes-mount.tftpl.yaml"))
}

resource "azapi_resource" "aio_targets_data_historian" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsOrchestrator/Targets@2023-10-04-preview"
  name                      = "${var.name}-tgt-dh"
  location                  = var.location
  parent_id                 = data.azurerm_resource_group.this.id

  depends_on = [
    azurerm_key_vault_secret.grafana_admin_user,
    azurerm_key_vault_secret.influxdb_admin_password,
    azurerm_key_vault_secret.influxdb_admin_token,
  ]

  body = jsonencode({
    extendedLocation = {
      name = local.custom_locations_id
      type = "CustomLocation"
    }

    properties = {
      scope   = var.aio_cluster_namespace
      version = var.datahistorian_targets_main_version
      components = [
        {
          name = "data-historian-spc"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(templatefile("./manifests/data-historian-spc.tftpl.yaml", {
              aio_cluster_namespace = var.aio_cluster_namespace
              key_vault_name        = local.key_vault_name
              tenant_id             = data.azurerm_client_config.current.tenant_id
            }))
          }
        },
        {
          name = "influxdb"
          type = "helm.v3"
          properties = {
            chart = {
              repo = "https://helm.influxdata.com"
              name = "influxdb2"
            }
            values = {
              adminUser = {
                user             = var.influxdb_admin_user
                organization     = var.influxdb_admin_organization
                bucket           = var.influxdb_admin_bucket
                retention_policy = var.influxdb_admin_bucket_retention_policy
                existingSecret   = var.should_create_secrets_in_key_vault ? "data-historian-secret" : null
              }
              persistence = {
                enabled      = true
                useExisting  = var.influxdb_persistence_should_use_existing_pvc
                name         = var.influxdb_persistence_pvc_name
                storageClass = var.influxdb_persistence_pvc_storage_class
                size         = var.influxdb_persistence_size
              }
              volumes     = !var.should_create_secrets_in_key_vault ? null : local.volume_mounts.volumes
              mountPoints = !var.should_create_secrets_in_key_vault ? null : local.volume_mounts.mountPoints
            }
          }
          dependencies = ["data-historian-spc"]
        },
      ]

      topologies = [
        {
          bindings = [
            {
              role     = "helm.v3"
              provider = "providers.target.helm"
              config = {
                inCluster = "true"
              }
            },
            {
              role     = "yaml.k8s"
              provider = "providers.target.kubectl"
              config = {
                inCluster = "true"
              }
            }
          ]
        }
      ]
    }
  })
}

