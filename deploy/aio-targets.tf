locals {
  volume_mounts      = yamldecode(file("./manifests/volumes-mount.tftpl.yaml"))
  telegraf_conf_file = file("./manifests/telegraf/telegraf.tftpl.conf")
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

resource "azapi_resource" "aio_targets_http_echo" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsOrchestrator/Targets@2023-10-04-preview"
  name                      = "${var.name}-tgt-he"
  location                  = var.location
  parent_id                 = data.azurerm_resource_group.this.id

  body = jsonencode({
    extendedLocation = {
      name = local.custom_locations_id
      type = "CustomLocation"
    }

    properties = {
      scope   = var.echo_cluster_namespace
      version = var.echo_targets_main_version
      components = [
        {
          name = "echo-deployment"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(file("./manifests/echo/echo-deployment.tftpl.yaml"))
          }
        },
        {
          name = "echo-service"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(file("./manifests/echo/echo-service.tftpl.yaml"))
          }
        },
      ]

      topologies = [
        {
          bindings = [
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

resource "azapi_resource" "aio_targets_telegraf" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsOrchestrator/Targets@2023-10-04-preview"
  name                      = "${var.name}-tgt-tg"
  location                  = var.location
  parent_id                 = data.azurerm_resource_group.this.id

  depends_on = [
    azapi_resource.aio_targets_data_historian
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
          name = "telegraf-deployment"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(templatefile("./manifests/telegraf/telegraf-deployment.tftpl.yaml", {
              telegraf_conf_hash = sha256(local.telegraf_conf_file)
            }))
          }
        },
        {
          name = "telegraf-service"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(file("./manifests/telegraf/telegraf-service.tftpl.yaml"))
          }
        },
        {
          name = "telegraf-configmap"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(templatefile("./manifests/telegraf/telegraf-configmap.tftpl.yaml", {
              telegraf_conf = join("\n", [for line in split("\n", local.telegraf_conf_file) : "    ${line}"])
            }))
          }
        },
      ]

      topologies = [
        {
          bindings = [
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

resource "azapi_resource" "aio_targets_grafana" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsOrchestrator/Targets@2023-10-04-preview"
  name                      = "grafana"
  location                  = var.location
  parent_id                 = data.azurerm_resource_group.this.id

  depends_on = [
    azapi_resource.aio_targets_data_historian
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
          name = "grafana"
          type = "helm.v3"
          properties = {
            chart = {
              repo = "https://grafana.github.io/helm-charts"
              name = "grafana"
            }
            values = {
              admin = {
                existingSecret = var.should_create_secrets_in_key_vault ? "grafana-secret" : null
                userKey        = "admin-user"
                passwordKey    = "admin-password"
              }
              envValueFrom = {
                INFLUXDB_TOKEN = {
                  secretKeyRef = {
                    key  = "admin-token"
                    name = "data-historian-secret"
                  }
                }
              }
              envFromSecrets = [
                {
                  name     = "data-historian-secret"
                  optional = false
                }
              ]
              datasources = {
                "datasources.yaml" = {
                  apiVersion = 1
                  datasources = [
                    {
                      name   = "InfluxDB"
                      type   = "influxdb"
                      access = "proxy"
                      url    = "http://influxdb-influxdb2"
                      secureJsonData = {
                        token = "$INFLUXDB_TOKEN"
                      }
                      jsonData = {
                        version       = "Flux"
                        organization  = var.influxdb_admin_organization
                        defaultBucket = var.influxdb_admin_bucket
                        tlsSkipVerify = true
                      }
                      isDefault = true
                      editable  = true
                    }
                  ]
                }
              }
            }
          }
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
            }
          ]
        }
      ]
    }
  })
}
