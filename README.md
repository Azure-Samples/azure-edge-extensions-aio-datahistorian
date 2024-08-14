# Azure Edge Extensions AIO Data Historian

InfluxDB-based Data Historian, deployed and managed by Azure IoT Operations.

> [!WARNING]  
> This Azure Edge Extensions has confirmed compatiblity with the 0.5.0 preview version of Azure IoT Operations. Please review
> [AIO release notes](https://github.com/Azure/azure-iot-operations/releases) for current preview version releases.

## Features

This project framework provides the following features:

* InfluxDB deployment and configuration.
* Secret generation with Azure Key Vault and access using Azure Key Vault Secrets Store CSI Driver.
* Telegraf for pipelines and transformation into InfluxDB.
* Azure IoT Operations Orchestrator for deploying and configuring the Data Historian in the cluster.
* Azure IoT Operations Data Processor for managing the data that's captured in the Data Historian.

## Getting Started

### Prerequisites

- (Optionally for Windows) [WSL](https://learn.microsoft.com/windows/wsl/install) installed and setup.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) available on the command line where this will be deployed.
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) available on the command line where this will be deployed.
- Cluster with Azure IoT Operations deployed -> This project assumes [azure-edge-extensions-aio-iac-terraform](https://github.com/Azure-Samples/azure-edge-extensions-aio-iac-terraform) was used, however, any cluster with AIO deployed will work.
- Owner access to a Resource Group with an existing cluster configured and connected to Azure Arc.

### Quickstart

1. Login to the AZ CLI:
    ```shell
    az login --tenant <tenant>.onmicrosoft.com
    ```
    - Make sure your subscription is the one that you would like to use: `az account show`.
    - Change to the subscription that you would like to use if needed:
      ```shell
      az account set -s <subscription-id>
      ```
2. Add a `<unique-name>.auto.tfvars` file to the root of the [deploy](deploy) directory that contains the following:
    ```hcl
    // <project-root>/deploy/<unique-name>.auto.tfvars

    name = "<unique-name>"
    location = "<location>"
    ```
3. From the [deploy](deploy) directory execute the following:
   ```shell
   terraform init
   terraform apply
   ```

## Usage

After the Terraform in this project has been applied, you should be able to connect to your cluster using the `az connectedk8s proxy` command:

```shell
az connectedk8s proxy -g rg-<unique-name> -n arc-<unique-name>
```

If you have a simulator set up from [azure-edge-extensions-aio-iac-terraform](https://github.com/Azure-Samples/azure-edge-extensions-aio-iac-terraform) or from a the Azure IoT Operations install, then there should be data flowing into the topics in Azure IoT Operations MQ broker. You can validate that there is data flowing by `kubectl exec` into a pod in your cluster that's setup with mqttui. If you deployed the azure-edge-extensions-aio-iac-terraform repo then you should already have this pod. To *exec* into this pod, run the following command:

```shell
kubectl exec -it -n aio deployments/mqtt-client -c mqtt-client -- sh
```

Once inside the pod you can run the following command to open mqttui and subscribe to all of the topics:

```shell
mqttui -b mqtts://aio-mq-dmqtt-frontend:8883 -u '$sat' --password $(cat /var/run/secrets/tokens/mq-sat) --insecure
```

> NOTE: This method was adapted from [Azure IoT Operations Documentation - Verify data is flowing](https://learn.microsoft.com/azure/iot-operations/get-started/quickstart-add-assets#verify-data-is-flowing) and can be referenced if needed.

### Connect to InfluxDB

If there is data flowing within the topics of your broker then InfluxDB should be filling with this data. Connect to your InfluxDB locally by first configuring `kubectl port-forward`:

```shell
kubectl port-forward service/influxdb-influxdb2 8086:80 -n aio
```

Then open a web browser and navigate to `http://localhost:8086`. Next, get your admin username and password by either referring to the Azure Key Vault Secret that was added after applying the Terraform, or if you've configured the username and password directly, use that instead.

Navigate to the datahistorian default bucket and run a query to see the measurements that have been added.
