provider "aws" {
  region = "us-east-1"
}

module "proj_mod" { // This creates a webserver using the parameters defined in the modules/project folder
  #source = "../modules/webProject" // Use this line if your module is in your local disk
  source = "git@github.com:ikuzoije/terraform_webProject_module.git//modules/webProject" // Pulls from the github repository
  tags = {
    Owner       = "Ikenna Uzoije MODULE" // Adding this tag attribute overrides the tag in the variable.tf file in the module
    Environment = "Prod"
    Project     = "WebServer Bootstrap"
    Creator     = "Use_Module Resource"
  }
  // Add more attributes to this block to override the variables used in the module we're calling
}
