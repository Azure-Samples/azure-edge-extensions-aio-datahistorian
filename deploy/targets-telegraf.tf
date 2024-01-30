locals {
  telegraf_conf_file = file("./manifests/telegraf/telegraf.tftpl.conf")
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
          name = "telegraf-pdb"
          type = "yaml.k8s"
          properties = {
            resource = yamldecode(file("./manifests/telegraf/telegraf-pdb.tftpl.yaml"))
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

