resource "azapi_resource" "aio_targets_http_echo" {
  count                     = var.should_deploy_http_echo_service ? 1 : 0
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