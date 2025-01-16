# Complete Example

This example demonstrates how to use the spacelift-automation child-module as a root-module to manage Spacelift stacks, including the ability for Spacelift to manage its own configuration.

Normally, this directory would contain a simple root module to spin up a basic example. To showcase a more practical use case where Spacelift manages its own infrastructure, we’ve moved the configuration to the expected path: [examples/complete/root-modules/spacelift-automation/](./root-modules/spacelift-automation/).

By doing this, we provide an example of how to set up Spacelift to automate the management of your infrastructure stacks, including itself.

## Use the Example

1. Prerequisites:
   - Replace the following configuration files with your own values:
     - `backend.tf.json`: Configure your Terraform backend settings
     - `main.tf`: Because this root module only has one instance, we manage the variables passed to it via the `main.tf` file. You'll want to change those values to match your own.
     - `stacks/common.yaml`: Define your stack configuration
       > **Important:** These files may contain sensitive information. Ensure you:
       >
       > - Remove any hardcoded credentials or sensitive values
       > - Have appropriate Spacelift ([`SPACELIFT_API_KEY_*`](https://docs.spacelift.io/concepts/spacectl#spacelift-api-keys) environment variables) and AWS permissions
       > - Follow your organization's security practices
2. Navigate to the spacelift-automation root-modules directory:

   ```sh
   cd ./root-modules/spacelift-automation/
   ```

3. Initialize Terraform:

   ```sh
   tofu init
   ```

4. Review the Terraform plan:

   ```sh
   tofu plan
   ```

5. Apply the Terraform plan:

   ```sh
   tofu apply
   ```

This will set up the Spacelift Stack that manages itself and the rest of the Stacks in the root-modules directory as well.
