variable "aws_region" {
  description = "Region where resource is being Provisioned"
  type        = string // Could be number or boolean
  default     = "us-east-1"
}

variable "ami_id_per_region" {
  description = "My Custom AMI id per Region"
  default = {
    "us-east-1"  = "ami-026b57f3c383c2eec"
    "us-west-2"  = "ami-0e472933a1395e172"
    "us-west-1"  = "ami-08d9a394ac1c2994c"
    "eu-west-1"  = "ami-0ce1e3f77cd41957e"
    "ap-south-1" = "ami-08f63db601b82ff5f"
  }
}

variable "env" {
  default = "prod"
}

variable "iam_users" {
  description = "List of IAM Users to create"
  default = [
    "TC@uzoije.net",
    "JT@uzoije.net",
    "George@uzoije.net",
    "Toheeb@uzoije.net",
    "Obinne@uzoije.net",
    "Samigbo@uzoije.net",
    "Mike@uzoije.net"
  ]

}

variable "instance_size" {
  description = "EC2 Instance Size to provision"
  default = {
    prod       = "t2.medium"
    staging    = "t2.small"
    dev        = "t2.micro"
    my_default = "t2.nano"
  }
}

variable "servers_settings" {
  type = map(any)
  default = {
    Collaboration = {
      ami           = "ami-026b57f3c383c2eec"
      instance_size = "t2.small"
      root_disksize = 20
      encrypted     = true
    }
    Mail = {
      ami           = "ami-026b57f3c383c2eec"
      instance_size = "t2.micro"
      root_disksize = 10
      encrypted     = false
    }
  }
}

variable "create_bastion" {
  description = "Provision Bastion Server YES/NO"
  default     = "NO"
}

variable "port_list" {
  description = "List of Ports to open for WebServer"
  default = {
    prod = ["80", "443"]
    rest = ["80", "443", "8080", "22"]
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(any)
  default = {
    Owner       = "Ikenna Uzoije"
    Environment = "Prod"
    Project     = "WebServer Bootstrap"
  }
}

variable "key_pair" {
  description = "SSH Key pair name to ingest into EC2"
  type        = string
  default     = "Terraform_main_key" // Change default to the key_pair available to be used 
  sensitive   = true
}

variable "password" {
  description = "Please Enter Password with length of 10 characters!"
  type        = string
  sensitive   = true
  default     = 1234567890
  validation {
    condition     = length(var.password) == 10
    error_message = "Your Password must be exactly 10 characters!"
  }
}
