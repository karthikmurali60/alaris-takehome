# Helm Charts Installation Guide

- Helm charts are used to install the required components on the Kubernetes cluster -
  - `cnpg-operator` - to manage PostgreSQL clusters
  - `cert-manager` - to manage TLS certificates, required for working with `barman-cloud-plugin`

- The helm installation is automated using a GitHub Actions workflow. Follow these steps -
  1. Go to the Actions tab in the GitHub repository.
  2. Select the workflow named `Install Helm Charts`.
  3. Click on the `Run workflow` button.

- The workflow will install the necessary helm charts on the Kubernetes cluster.
 