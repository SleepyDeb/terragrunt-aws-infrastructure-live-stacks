include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::ssh://git@github.com/org/terragrunt-aws-infrastructure-catalog.git//stacks/web-application-stack?ref=v1.0.0"
}

inputs = {
  environment       = "non-prod"
  region            = "us-east-1"
  vpc_cidr_block    = "10.0.1.0/24"
  instance_type     = "t3.micro"
  name_prefix       = "nonprod-webapp"
  common_tags       = {
    Environment = "non-prod"
    ManagedBy   = "Terragrunt"
  }
}