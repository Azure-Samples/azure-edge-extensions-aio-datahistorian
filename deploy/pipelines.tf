data "azapi_resource" "aio_dp" {
  type      = "Microsoft.IoTOperationsDataProcessor/instances@2023-10-04-preview"
  name      = "dp-${var.name}"
  parent_id = data.azurerm_resource_group.this.id
}

resource "azapi_resource" "aio_datahistorian_opcua_pipeline" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsDataProcessor/instances/pipelines@2023-10-04-preview"
  name                      = "datahistorian-opcua"
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
        displayName = "MQTT Topics - OPC UA Broker"
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
          "aio/data/opc.tcp/#"
        ]
        viewOptions = {
          position = {
            x = 0
            y = 80
          }
        }

        next = [
          "transformTelegraf"
        ]
      }
      stages = {
        transformTelegraf = {
          displayName = "Transform - Telegraf OPC UA Payload"
          type        = "processor/transform@v1",
          next = [
            "telegrafCallOut"
          ]
          viewOptions = {
            position = {
              x = 0
              y = 224
            }
          }
          expression = <<-EOT
            .payload.payload = ([
              .payload.payload | to_entries | .[] | {
                CapabilityId: .key,
                SourceTimestamp: .value.SourceTimestamp,
                Value: .value.Value
              }
            ])
          EOT
        }
        telegrafCallOut = {
          displayName = "HTTP Call Out - Telegraf OPC UA Endpoint"
          type        = "processor/http@v1"

          authentication = {
            type = "none"
          }
          url    = "http://telegraf:8081/opcua"
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
              type = "raw"
            }
          }
          viewOptions = {
            position = {
              x = 0,
              y = 416
            }
          }
          next = [
            "output"
          ]
        }
        output = {
          displayName = "MQ Output - Telegraf Response"
          description = "Telegraf returns empty if successful"
          type        = "output/mqtt@v1"

          authentication = {
            type = "serviceAccountToken"
          }
          broker = "tls://aio-mq-dmqtt-frontend:8883"
          format = {
            path = "."
            type = "raw"
          }
          qos = 1
          topic = {
            type  = "static",
            value = "telegraf/opcua/response"
          }
          userProperties = []
          viewOptions = {
            position = {
              x = 0,
              y = 624
            }
          }
        }
      }
    }
  })
}

resource "azapi_resource" "aio_datahistorian_events_pipeline" {
  schema_validation_enabled = false
  type                      = "Microsoft.IoTOperationsDataProcessor/instances/pipelines@2023-10-04-preview"
  name                      = "datahistorian-events"
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
        displayName = "MQTT Topics - AIO"
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
          "transformTelegraf"
        ]
      }
      stages = {
        transformTelegraf = {
          displayName = "Transform - Telegraf Event Payload"
          type        = "processor/transform@v1",
          next = [
            "telegrafCallOut"
          ]
          viewOptions = {
            position = {
              x = 0
              y = 224
            }
          }
          expression = <<-EOT
            .payload = {
              data: (.payload | tojson)
            }
          EOT
        }
        telegrafCallOut = {
          displayName = "HTTP Call Out - Telegraf Event Endpoint"
          type        = "processor/http@v1"

          authentication = {
            type = "none"
          }
          url    = "http://telegraf:8080/generic"
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
              type = "raw"
            }
          }
          viewOptions = {
            position = {
              x = 0,
              y = 416
            }
          }
          next = [
            "output"
          ]
        }
        output = {
          displayName = "MQ Output - Telegraf Response"
          description = "Telegraf returns empty if successful"
          type        = "output/mqtt@v1"

          authentication = {
            type = "serviceAccountToken"
          }
          broker = "tls://aio-mq-dmqtt-frontend:8883"
          format = {
            path = "."
            type = "raw"
          }
          qos = 1
          topic = {
            type  = "static",
            value = "telegraf/generic/response"
          }
          userProperties = []
          viewOptions = {
            position = {
              x = 0,
              y = 624
            }
          }
        }
      }
    }
  })
}
