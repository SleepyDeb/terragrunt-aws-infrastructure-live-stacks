locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

unit "dynamo" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/dynamodb-table"

  path = "dyn"

  values = {    
    version = "main"

    name              = "${locals.root_vars.deployment_name}-table"
    hash_key          = "id"
    hash_key_type     = "STRING"
  }
}