# Terragrunt AWS Infrastructure Live Stacks

## Live Environment Structure

The live stacks directory contains environment-specific infrastructure configurations for deploying the AWS infrastructure.

- `non-prod/` - Non-production environment configurations for development, testing, and staging.
- `prod/` - Production environment configurations.
- Each environment contains region-specific directories (e.g., `us-east-1`) and application-specific stacks (e.g., `web-application`).

## Environment-Specific Configurations

Each environment and region directory contains Terragrunt configuration files (`terragrunt.hcl`) that specify:

- Backend configuration for remote state storage (S3 bucket and DynamoDB table).
- Inputs and variables specific to the environment.
- Dependencies between stacks and modules.
- Provider configurations and region settings.

## Deployment Procedures

To deploy or update infrastructure in a specific environment:

```bash
# Navigate to the environment and stack directory
cd terragrunt-aws-infrastructure-live-stacks/non-prod/us-east-1/web-application

# Plan the changes
terragrunt run-all plan

# Apply the changes
terragrunt run-all apply
```

Repeat the process for the production environment by changing the path accordingly.

## State Management

- Terraform state is stored remotely in an S3 bucket to enable collaboration and state sharing.
- A DynamoDB table is used for state locking to prevent concurrent modifications.
- Each environment and stack has its own isolated state to ensure environment separation and reduce risk.

## Environment Promotion Workflow

- Changes are first deployed and tested in the non-production environment.
- After validation, the same configurations are promoted to the production environment.
- Promotion involves applying the same Terragrunt configurations in the `prod` directory.
- This workflow ensures stability and reduces the risk of introducing breaking changes into production.

---

This documentation provides guidance for managing live infrastructure deployments using Terragrunt. For reusable modules and stack definitions, refer to the `terragrunt-aws-infrastructure-catalog` directory.