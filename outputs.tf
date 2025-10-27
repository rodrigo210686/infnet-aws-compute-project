output "infnet_proj_1_vpc_id" {
  value = module.networking.infnet_proj_1_vpc_id
}

output "infnet_proj_1_public_subnets" {
  value = module.networking.infnet_proj_1_public_subnets
}

output "infnet_proj_1_private_subnets" {
  value = module.networking.infnet_proj_1_private_subnets
}

output "infnet_proj_1_private_subnets_cidr_blocks" {
  value = module.networking.infnet_proj_1_private_subnets_cidr_blocks
}


output "sg_alb" {
  value = module.security_group.sg_alb
} 

output "sg_ec2" {
  value = module.security_group.sg_ec2
}

output "app_infnet_proj_1_launch_template_id" {
  value = module.launch_template.app_infnet_proj_1_launch_template_id
}

/*
## Private Subnet IDs for Auto Scaling Group
output "private_subnet_ids_for_asg" {
  value = module.networking.infnet_proj_1_private_subnets
} */

## Load Balancer Target Group ARN
output "infnet_proj_1_lb_target_group_arn" {
  value = module.lb_target_group.infnet_proj_1_lb_target_group_arn
} 

output "sg_ecs" {
  value = module.security_group.sg_ecs
} 

output "sg_ecs_alb" {
  value = module.security_group.sg_ecs_alb
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.codebuild.codebuild_project_name
}