
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  app_vars = read_terragrunt_config(find_in_parent_folders("app.hcl"))
  deployment_name = "${local.env_vars.locals.env_name}-${local.app_vars.locals.app_name}"
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