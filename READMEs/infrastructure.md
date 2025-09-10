# Infrastructure Provisioning using Terraform

The `infra` directory contains Terraform code to provision the necessary infrastructure on DigitalOcean for the Alaris take-home project. This includes provisioning - 
    - Getting data related to DigitalOcean project
    - Kubernetes cluster
    - Spaces Bucket and related CORS configuraiton
    - Volumes for PostgreSQL clusters
    - Container Registry (DOR) for hosting Docker images

## Deployment Steps

- The infrastructure will be provisioned via GitHub Actions workflows. To provision the infrastructure, follow these steps:

    1. Go to the Actions tab in the GitHub repository.
    2. Select the workflow named `Provision DigitalOcean Resources`.
    3. Click on the `Run workflow` button.

- This will trigger the workflow to provision the infrastructure using Terraform. The workflow will use the secrets stored in GitHub Secrets for authentication and configuration.

- The variables required for the Terraform code are set in the terraform.tfvars file located in the `infra/task` directory. This is designed in such a way that further enviraonments can be easily added, just add another folder and a corresponding terraform.tfvars file. You can modify this file to change the configuration as needed.

- The workflow will create the necessary resources on DigitalOcean and store the Terraform state in the `alaris-takehome-task-tfstate` Spaces bucket.

- Once the workflow completes successfully, the infrastructure will be provisioned and ready for use.