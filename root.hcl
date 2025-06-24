# Common locals for naming and tags
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables we need for easy access
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.aws_region
  
  common_tags = {
    Project     = "WebApplication"
    Environment = local.account_name
    ManagedBy   = "Terragrunt"
  }
}

# Generate AWS provider block with default region
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = local.region
}
EOF
}

# Remote state configuration with S3 backend and DynamoDB locking
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "your-terraform-state-bucket" # Replace with your bucket name
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1" # Replace with your bucket region
    dynamodb_table = "terraform-locks" # Replace with your DynamoDB table name
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
)
