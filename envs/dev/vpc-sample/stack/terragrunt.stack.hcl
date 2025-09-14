
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  app_vars = read_terragrunt_config(find_in_parent_folders("app.hcl"))
  
  # Extract the variables we need for easy access
  env_name = local.env_vars.locals.env_name
  app_name = local.app_vars.locals.app_name
  deployment_name = "${local.env_name}-${local.app_name}"
}

unit "vpc" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/vpc-import"

  path = "vpc-import"

  values = {
    version = "main"

    vpc_id = lookup(local.env_vars.locals, "vpc_id", null) 
    default = lookup(local.env_vars.locals, "default_vpc", false)
  }
}