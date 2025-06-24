locals {
  table_name = "sample-table"
}

unit "dynamo" {
  source = "git::git@github.com:SleepyDeb/terragrunt-aws-infrastructure-catalog.git//units/dynamodb-table"

  path = "dyn"

  values = {    
    version = "main"

    name              = "${local.table_name}"
    hash_key          = "id"
    hash_key_type     = "S" # STRING
  }
}