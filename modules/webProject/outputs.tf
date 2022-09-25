# ---------------------- OUTPUT SECTION ------------------------------ #
# Moving this section to the outputs.tf file

// AWS Region Name, Description, Account ID, AZs
output "region_name" {
  value = data.aws_region.current.name
}

output "region_description" {
  value = data.aws_region.current.description
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  value = data.aws_availability_zones.currentAZ.names
}

// IAM Users:
// Map Users to their ARNS
output "iam_users_map" {
  value = {
    for user in aws_iam_user.user :
    user.name => user.arn    // map user names to their arns
    if length(user.name) > 7 #This condition only prints users that have their usernames more than 7 characters
  }
}

// VPC Outputs
output "all_vpc_ids" {
  value = data.aws_vpcs.vpcs.ids
}

// Security Group IDs
output "my_security_group_id" {
  value = aws_security_group.General_SG.id
}

// Print out instance ID with public and private IP
output "instance_info" {
  value = [
    // Prints out info on the web_server
    "Server with ID: ${aws_instance.web_server.id} has Public IP: ${aws_instance.web_server.public_ip} and Private IP: ${aws_instance.web_server.private_ip}",
    // Prints out info on the application and database server
    [
      for x in aws_instance.servers :
      "Server with ID: ${x.id} has Public IP: ${x.public_ip} and Private IP: ${x.private_ip}"
    ],
    // Prints out information on the Collaboration and Mail server
    [
      for y in aws_instance.extra_server :
      "Server with ID: ${y.id} has Public IP: ${y.public_ip} and Private IP: ${y.private_ip}"
    ],
    // Prints out information on the bastion host server
    var.create_bastion == "YES" ? "Server with ID: ${aws_instance.bastion_server["Bastion"].id} has Public IP: ${aws_instance.bastion_server["Bastion"].public_ip} and Private IP: ${aws_instance.bastion_server["Bastion"].private_ip}" : null
  ]
}


// RDS Database outputs
output "rds_address" {
  value = aws_db_instance.prod_db.address
  #value = jsondecode(data.aws_secretsmanager_secret_version.rds_params.secret_string)["rds_address"]
  // If you use the second value parameter with secrets manager, set "sensitive" flag to true
}

output "rds_port" {
  value = aws_db_instance.prod_db.port
  #value = jsondecode(data.aws_secretsmanager_secret_version.rds_params.secret_string)["rds_port"]
}

output "rds_username" {
  value = aws_db_instance.prod_db.username
  #value = jsondecode(data.aws_secretsmanager_secret_version.rds_params.secret_string)["rds_username"]
}

output "rds_password" {
  value = aws_db_instance.prod_db.password // This gets the password from the database instance attributes
  #value     = jsondecode(data.aws_secretsmanager_secret_version.rds_params.secret_string)["rds_address"]
  sensitive = true
  #value     = data.aws_ssm_parameter.rds_password.value  // This gets the password from the SSM parameter store
  #value     = random_password.main_rds.result // This gets the password from the password generator
  #value     = data.aws_secretsmanager_secret_version.rds_password.secret_string // This gets the password from the AWS Secrets Manager
}

/*
output "rds_all" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.rds_params.secret_string)
  sensitive = true
}
*/
# -------- End of Output Section --------------------------------------------- #
