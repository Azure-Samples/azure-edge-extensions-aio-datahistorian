data "azapi_resource" "aio_dp" {
  type      = "Microsoft.IoTOperationsDataProcessor/instances@2023-10-04-preview"
  name      = "dp-${var.name}"
  parent_id = data.azurerm_resource_group.this.id
}

resource "azapi_resource" "aio_datahistorian_pipeline" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsDataProcessor/instances/pipelines@2023-10-04-preview"
  name                      = "datahistorian"
  location                  = var.location
  parent_id                 = data.azapi_resource.aio_dp.id

  body = jsonencode({
    extendedLocation = {
      name = local.custom_locations_id
      type = "CustomLocation"
    }

    properties = {
      enabled = true,
      input = {
        displayName = "MQTT Topics"
        type        = "input/mqtt@v1"

        authentication = {
          type = "serviceAccountToken"
        }
        broker       = "tls://aio-mq-dmqtt-frontend:8883"
        cleanSession = false
        format = {
          type = "json"
        }
        partitionCount = 1
        partitionStrategy = {
          expression = ".topic"
          type       = "key"
        }
        qos = 1
        topics = [
          "aio/#"
        ]
        viewOptions = {
          position = {
            x = 0
            y = 80
          }
        }

        next = [
          "telegraf"
        ]
      }
      stages = {
        telegraf = {
          displayName = "Telegraf HTTP Call Out"
          type        = "processor/http@v1"

          authentication = {
            type = "none"
          }
          url    = "http://telegraf:8080/payload"
          method = "POST"
          request = {
            body = {
              path = "."
              type = "json"
            }
            headers = []
          }
          response = {
            body = {
              path = "."
              type = "json"
            }
          }
          viewOptions = {
            position = {
              x = 0,
              y = 260
            }
          }
          next = [
            "output"
          ]
        }
        output = {
          displayName = "MQTT Telegraf Output"
          type        = "output/mqtt@v1"

          authentication = {
            type = "serviceAccountToken"
          }
          broker = "tls://aio-mq-dmqtt-frontend:8883"
          format = {
            path = "."
            type = "json"
          }
          qos = 1
          topic = {
            type  = "static",
            value = "telegraf/response"
          }
          userProperties = []
          viewOptions = {
            position = {
              x = 0,
              y = 440
            }
          }
        }
      }
    }
  })
}