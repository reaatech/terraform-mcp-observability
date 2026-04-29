plugin "aws" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.9.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "ManagedBy", "Module"]
}
