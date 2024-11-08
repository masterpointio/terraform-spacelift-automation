# Complete Example

This example demonstrates how to use the spacelift-automation component to manage Spacelift stacks, including the ability for Spacelift to manage its own configuration.

Normally, this directory would contain a simple root module to spin up a basic example. To showcase a more practical use case where Spacelift manages its own infrastructure, we’ve moved the configuration to the expected path: [examples/complete/components/spacelift-automation/](./components/spacelift-automation/).

By doing this, we provide an example of how to set up Spacelift to automate the management of your infrastructure stacks, including itself.

## Use the Example

1. Prerequisites: Replace [backend.tf.json](./components/spacelift-automation/backend.tf.json), [example.tfvars](./components/spacelift-automation/tfvars/example.tfvars), and [example.yaml](./components/spacelift-automation/stacks/example.yaml) values with your own. The values in this repo are hardcoded for Masterpoint's automation and testing needs.
1. Navigate to the spacelift-automation component directory:
   ```sh
   cd ./components/spacelift-automation/
   ```
1. Initialize Terraform:
   ```sh
   tofu init
   ```
1. Select the worspace:
   ```sh
   tofu workspace select example
   ```
1. Review the Terraform plan:
   ```sh
   tofu plan -var-file tfvars/example.tfvars
   ```

This will set up the Spacelift stack that manages itself.
