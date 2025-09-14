
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  app_vars = read_terragrunt_config(find_in_parent_folders("app.hcl"))
  
  # Extract the variables we need for easy access
  env_name = local.env_vars.locals.env_name
  app_name = local.app_vars.locals.app_name
  deployment_name = "${local.env_name}-${local.app_name}"
}

unit "dynamo" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/dynamodb-table"

  path = "dyn"

  values = {
    version = "main"

    name              = "${local.deployment_name}-table"
    hash_key          = "id"
    hash_key_type     = "S" # STRING
  }
}

unit "backend-app" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/ecr-repository"
  path = "backend-app"

  values = {
    version = "main"

    name = "${local.deployment_name}-ecr"
    force_delete = true
    scan_on_push = false
  }
}

unit "vpc" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/vpc"
  path = "vpc"

  values = {
    version = "main"

    name = "${local.deployment_name}-vpc"
    vpc_cidr = "10.0.0.0/16"
    vpc_private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
    vpc_public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    vpc_azs = ["eu-west-1a", "eu-west-1b"]
  }
}