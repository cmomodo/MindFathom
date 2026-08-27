plugin "terraform" {
    # Plugin common attributes
    required_version = "1.15.9"
    enabled = true
    preset = "recommended"
}

plugin "aws" {
    enabled = true
    version = "0.48.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
