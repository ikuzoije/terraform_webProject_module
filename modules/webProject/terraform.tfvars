aws_region = "us-east-1"
key_pair   = "Terraform_main_key"
password   = 1234567890
tags = {
  Owner       = "Ikenna Uzoije"
  Environment = "Prod"
  Project     = "WebServer Bootstrap"
}
create_bastion = "YES"
