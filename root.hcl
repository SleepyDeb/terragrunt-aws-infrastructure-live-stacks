# Common locals for naming and tags
locals {  
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  app_vars = read_terragrunt_config(find_in_parent_folders("app.hcl"))  

  # Extract the variables we need for easy access
  env_name = local.env_vars.env_name
  app_name = local.app_vars.app_name
  account_id   = local.env_vars.aws_account_id
  aws_region   = local.env_vars.aws_region
  deployment_name = "${local.env_name}-${local.app_name}"

  common_tags = {
    Application     = local.app_name
    Environment = local.env_name
    ManagedBy   = "Terragrunt"
  }
}

# Generate AWS provider block with default region
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = local.aws_region
}
EOF
}

# Remote state configuration with S3 backend and DynamoDB locking
remote_state {
  backend = "s3"
  config = {
    encrypt        = false
    bucket         = "terraform-backend-${local.account_id}-${local.aws_region}"
    key            = "${local.app_name}/${local.env_name}/terragrunt.tfstate"
    region         = "${local.aws_region}"
    dynamodb_table = "terraform-backend-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

catalog {
  urls = [
    "https://github.com/SleepyDeb/terragrunt-infrastructure-catalog"
  ]
}

inputs = merge(
  local.app_vars.locals,
  local.env_vars.locals,
  {
    deployment_name = local.deployment_name
  }
)
