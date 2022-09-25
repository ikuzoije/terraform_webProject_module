// AWS Region Name, Description, Account ID, AZs
output "module_region_name" {
  value = module.proj_mod.region_name
}

output "module_region_description" {
  value = module.proj_mod.region_description
}

output "module_account_id" {
  value = module.proj_mod.account_id
}

output "module_availability_zones" {
  value = module.proj_mod.availability_zones
}

// IAM Users:
// Map Users to their ARNS
output "module_iam_users_map" {
  value = module.proj_mod.iam_users_map
}

// VPC Outputs
output "module_all_vpc_ids" {
  value = module.proj_mod.all_vpc_ids
}

// Security Group IDs
output "module_my_security_group_id" {
  value = module.proj_mod.my_security_group_id
}

// Print out instance ID with public and private IP
output "module_instance_info" {
  value = module.proj_mod.instance_info
}


// RDS Database outputs
output "module_rds_address" {
  value = module.proj_mod.rds_address
}

output "module_rds_port" {
  value = module.proj_mod.rds_port
}

output "module_rds_username" {
  value = module.proj_mod.rds_username
}

output "module_rds_password" {
  value     = module.proj_mod.rds_password
  sensitive = true
}

/*
output "module_rds_all" {
  value = module.proj_mod.rds_all
}
*/
# -------- End of Output Section --------------------------------------------- #
