#--------------------------------------------------
# Build Webserver during Bootstrap
#--------------------------------------------------

/*
provider "aws" {
  region = var.aws_region
  # already have the access and secret keys setup as environment variables
}
*/

/* // This backend has been moved to the ProjectRemote Folder 
terraform {
  backend "s3" {
    bucket = "ikenna-terraform-remote-state"            // Bucket where to SAVE Terraform State
    key    = "dev/WebServerBootStrap/terraform.tfstate" // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                                // Region where resources was created
  }
}
*/

/*
# Add new provider blocks to be able to deploy resources in a different region and/or in a different account
provider "aws" {
  region = "us-west-2"
  alias  = "PROD" // Gives the new region an alias so that resources provisioned in that region can follow it
  assume_role {
    // The main account assumes this role in the PROD account when it wants to provision resources in the prod account
    role_arn = ******************** // role ARN deleted for security reasons
  }
}
// Create a VPC in a different account and in a different region.
resource "aws_vpc" "prod_vpc" {
  provider   = aws.PROD
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "PROD VPC"
  }
}
*/

# Create a VPC for the project
# Create a two subnets (private and public)
# Create the elastic network interface
# Create the internet gateway 
# Create route tables to route traffic through the ENI and IGW

# -------- EXECUTE LOCAL AND REMOTE COMMANDS -------------- #
# Run a local command to log when terraform started
resource "null_resource" "terraform_start" {
  provisioner "local-exec" {
    command = "echo Terraform START: $(date) >> log.txt"
  }
}

# Though not best practice, this local-exec command sets the environment variables for AWS to use
resource "null_resource" "set_env_variables" {
  provisioner "local-exec" {
    command = "echo 'Environment Variables set' >> log.txt"
    // AWS access keys variables deleted from here for security reasons
  }
  depends_on = [
    null_resource.terraform_start
  ]
}

# --------------- DATA SOURCES for Output and Use in Code ------------ #
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "currentAZ" {}
data "aws_vpcs" "vpcs" {} // This gets data on all VPCs in the account
/*
data "aws_vpc" "default" {
  default = true
  tags = {
    Name = "default" // This takes in just the tag of the vpc referenced above
  }
} 
*/
data "aws_ami" "latest_linux" {
  owners      = ["137112412989"] // Owner Account ID gotten from the Amazon AMI page for the linux image
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"] // Dates and version numbers are replaced with a * to always get the latest
  }
}


# Use local variables 
locals {
  Region_fullname   = data.aws_region.current.description
  Number_of_AZs     = length(data.aws_availability_zones.currentAZ.names)
  Names_of_AZs      = join(",", data.aws_availability_zones.currentAZ.names)
  Full_Project_Name = "${var.tags["Project"]} running in ${local.Region_fullname}"
}

locals {
  Region_Info = "This Resource is in ${local.Region_fullname} consisting of ${local.Number_of_AZs} AZs"
}


# Create IAM Users using a for_each loop
resource "aws_iam_user" "user" {
  for_each = toset(var.iam_users)
  name     = each.value
}

# Create Elastic IP for the Web instance
resource "aws_eip" "instance_eip" {
  instance = aws_instance.web_server.id
  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} EIP for WebServer"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
  // ${var.tags["Environment"]} Extracts the environment attribute of the tag variable and use it in the name attribute of the tag
}

# Create EC2 instances for web, application and DB
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.latest_linux.id // Amazon Linux2 ami from the data source above
  instance_type          = lookup(var.instance_size, var.env, var.instance_size["my_default"])
  vpc_security_group_ids = [aws_security_group.General_SG.id]
  key_name               = var.key_pair

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 10
    encrypted   = (var.env == "prod") ? true : false // If the environment is prod, encrypt the root block device
  }

  dynamic "ebs_block_device" {
    for_each = var.env == "prod" ? [true] : [] // dynamic blocks take a list so if it isn't prod, give an empty list
    content {
      device_name = "/dev/sdb"
      volume_size = 40
      encrypted   = true
    }
  }


  # user_data              = file("user_data.sh")  # This is used for a static user_data file
  user_data = templatefile("user_data.sh.tpl", {
    f_name = "Ikenna"
    l_name = "Uzoije"
    names  = ["TC", "JT", "George", "Toheeb", "Obinne", "SamIgbo", "Mike"]
  }) // This passes these variables into the user_data.sh.tpl file and use those variables to build the user_data file

  // run a local-exec command inside an instance being provisioned to save the output in a file on your local machine
  provisioner "local-exec" {
    command = "echo The WebServer private IP is ${aws_instance.web_server.private_ip} >> log.txt"
  }

  // running a remote-exec command executes commands in the resource that's created (like a user_data)
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/ec2-user/terraform",
      "cd /home/ec2-user/terraform",
      "touch hello.txt",
      "echo 'Terraform was here ...' > terraform.txt"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip // Same as: aws_instance.web_server.public_ip
      private_key = file("${var.key_pair}.pem")
    }
  }

  depends_on = [ # This is an explicit dependency to force the dependency. You can add a list of resources the current one depends on
    aws_instance.servers["Application"],
    aws_instance.servers["Database"],
    null_resource.terraform_start
  ]

  volume_tags = { Name = "Disk-${var.env}" }

  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} WebServer Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  }) // This merges the unique name tag with the ones that are constant and expressed in the variables file

}

# Use a for_each loop to create the application and database servers
resource "aws_instance" "servers" {
  for_each               = toset(["Application", "Database"]) // Use a for_each loop to create 2 identical servers
  ami                    = data.aws_ami.latest_linux.id       // Amazon Linux2
  instance_type          = lookup(var.instance_size, var.env, var.instance_size["my_default"])
  vpc_security_group_ids = [aws_security_group.General_SG.id]
  key_name               = var.key_pair
  /*depends_on = [
    aws_instance.db_server
  ]*/
  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} ${each.value} Server Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}

# Use a for_each loop and pass in a map of values to create new EC2 Instances
resource "aws_instance" "extra_server" {
  for_each      = var.servers_settings
  ami           = each.value["ami"]
  instance_type = each.value["instance_size"]

  root_block_device {
    volume_size = each.value["root_disksize"]
    encrypted   = each.value["encrypted"]
  }

  volume_tags = {
    Name = "Disk-${each.key}"
  }
  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} ${each.key} Server Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}

# Create the bastion host if the user wants to create a bastion host (an EC2 server)
resource "aws_instance" "bastion_server" {
  for_each      = var.create_bastion == "YES" ? toset(["Bastion"]) : []
  ami           = data.aws_ami.latest_linux.id
  instance_type = lookup(var.instance_size, var.env, var.instance_size["my_default"])
  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} ${each.value} Server Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}


# ------- Instance Security Group Section ------------- #
# Create Security Group for instances
resource "aws_security_group" "General_SG" {
  name        = "General-SG"
  description = "Security Group for Web, App and DB Servers"

  dynamic "ingress" {
    # reduces the need to have multiple ingress blocks for each port. "Ingress" shows what kind of block it is replacing.
    for_each = lookup(var.port_list, var.env, var.port_list["rest"]) # The rest port_list is the default option
    content {
      description = "Allow all tcp traffic on Ports 80, 443, 8080"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Putting one specific IP means only that IP address can access this Security Group
    }
  }

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from any IP so we can run the remote-exec rule
    #cidr_blocks = ["172.31.0.0/16"] # Allow only IPs in the VPC to SSH into the instance
  }

  egress {
    description      = "Allow all ports"
    from_port        = 0 # Means all ports allowed
    to_port          = 0
    protocol         = "-1" # Any protocol allowed
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} General SG by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}
# --------- End of Instance Security Group Section --------- #

# ---------- RDS Database Instance Creation ---------- #
# Create RDS Database instance
resource "aws_db_instance" "prod_db" {
  identifier           = "prodmysqlrds"
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "prod_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  apply_immediately    = true
  username             = "administrator"
  password             = data.aws_ssm_parameter.rds_password.value # If using AWS Systems Manager Parameter Store
  #password             = data.aws_secretsmanager_secret_version.rds_password.secret_string # If using AWS Secretes Manager
}
# -------- End of RDS Database Instance ---------------- #

# -------- Random Password Generator ---------------- #
# Generate random Password
resource "random_password" "main_rds" { # Random password generator
  length           = 20
  special          = true    # Use special characters Default: !@#$%&*()-_=+[]{}<>:?
  override_special = "#!()_" # This restricts which special characters to use
}
# -------- End of Random Password Generator ---------------- #

# ------------ Systems Manager Parameter Store Implementation ---------- #
# Store password in the SSM resource
resource "aws_ssm_parameter" "rds_password" {
  name        = "/prod_db/prodmysqlrds/password"
  description = "Master Password for RDS Database"
  type        = "SecureString"
  value       = random_password.main_rds.result
}

# Retrieve Password from SSM parameter store
data "aws_ssm_parameter" "rds_password" {
  name       = "/prod_db/prodmysqlrds/password"
  depends_on = [aws_ssm_parameter.rds_password]
}
# ---------- End of Systems Manager Parameter Store Implementation ------ #

/*
# ----------- AWS Secrets Manager Implementation ------------ #
# Store Password in AWS Secrets Manager
# First Create location to store the secret
resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "/prod_db/prodmysqlrds/password"
  description             = "Master Password for RDS Database"
  recovery_window_in_days = 0 # Set to Zero means we can't restore the secrets anymore once you delete it
}

# Then Store the password
resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id # Where to store the secret
  secret_string = random_password.main_rds.result           # What to store
}

# How to Retrieve Stored Password
data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id  = aws_secretsmanager_secret.rds_password.id
  depends_on = [aws_secretsmanager_secret_version.rds_password]
}

# Store All RDS parameters
# Create storage location
resource "aws_secretsmanager_secret" "rds_params" {
  name                    = "/prod_db/prodmysqlrds/rdsparams"
  description             = "All Details for RDS Database"
  recovery_window_in_days = 0 # Set to Zero means we can't restore the secrets anymore once you delete it
}

# Store the parameters
resource "aws_secretsmanager_secret_version" "rds_params" {
  secret_id = aws_secretsmanager_secret.rds_params.id # Where to store the secret
  secret_string = jsonencode({
    rds_address  = aws_db_instance.prod_db.address
    rds_port     = aws_db_instance.prod_db.port
    rds_username = aws_db_instance.prod_db.username
    rds_password = random_password.main_rds.result
  }) # We store a json object
}

# Retrieve the parameters
data "aws_secretsmanager_secret_version" "rds_params" {
  secret_id  = aws_secretsmanager_secret.rds_params.id
  depends_on = [aws_secretsmanager_secret_version.rds_params]
}

# ---------- End of AWS Secrets Manager Implementation Block --------- #
*/


# ---------------------- OUTPUT SECTION -------------------------------------- #
# Moving this section to the outputs.tf file
# -------- End of Output Section --------------------------------------------- #

# Run a local command to log when terraform ended
resource "null_resource" "terraform_end" {
  provisioner "local-exec" {
    command = "echo Terraform STOP: $(date) >> log.txt"
  }
  depends_on = [
    aws_instance.servers,
    aws_instance.web_server,
    aws_db_instance.prod_db,
    null_resource.terraform_start
  ]
}
