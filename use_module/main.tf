provider "aws" {
  region = "us-east-1"
}

module "proj_mod" { // This creates a webserver using the parameters defined in the modules/project folder
  source = "../modules/webProject"
  tags = { // Adding this tag attribute overrides the tag in the variable.tf file in the module
    Owner       = "Ikenna Uzoije MODULE"
    Environment = "Prod"
    Project     = "WebServer Bootstrap"
    Creator     = "Use_Module Resource"
  }
  // Add more attributes to this block to override the variables used in the module we're calling
}
