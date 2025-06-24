
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