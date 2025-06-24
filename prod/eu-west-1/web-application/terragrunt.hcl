include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::ssh://git@github.com/org/terragrunt-aws-infrastructure-catalog.git//stacks/web-application-stack?ref=v1.0.0"
}

inputs = {
  environment       = "prod"
  region            = "us-east-1"
  vpc_cidr_block    = "10.0.0.0/16"
  instance_type     = "t3.medium"
  name_prefix       = "prod-webapp"
  high_availability = true
  common_tags       = {
    Environment = "prod"
    ManagedBy   = "Terragrunt"
  }
}