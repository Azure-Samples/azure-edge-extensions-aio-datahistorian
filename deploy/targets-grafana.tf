locals {
  grafana_sample_dashboard = file("./manifests/grafana/grafana-sample-dashboard.json")
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
          name = "grafana-dashboard-configmap"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(templatefile("./manifests/grafana/grafana-dashboard-configmap.tftpl.yaml", {
              grafana_sample_dashboard = join("\n", [for line in split("\n", local.grafana_sample_dashboard) : "    ${line}"])
            }))
          }
        },
        {
          name = "grafana"
          type = "helm.v3"
          dependencies = [
            "grafana-dashboard-configmap"
          ]
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
              dashboardProviders = {
                "dashboardproviders.yaml" = {
                  apiVersion = 1,
                  providers = [
                    {
                      name          = "default"
                      orgId         = 1
                      folder        = ""
                      type          = "file"
                      disableDelete = false
                      editable      = true
                      options = {
                        path = "/var/lib/grafana/dashboards/default"
                      }
                    }
                  ]
                }
              }
              dashboardsConfigMaps = {
                default = "grafana-sample-dashboard"
              }
              datasources = {
                "datasources.yaml" = {
                  apiVersion = 1
                  datasources = [
                    {
                      name   = "InfluxDB"
                      uid    = "influxdbdatasource"
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
