
module "networking" {
  source                       = "./networking"
  vpc_cidr                     = var.vpc_cidr
  vpc_name                     = var.vpc_name
  cidr_public_subnet           = var.cidr_public_subnet
  us_availability_zone         = var.us_availability_zone
  cidr_private_subnet          = var.cidr_private_subnet
  public_subnet_ipv6_prefixes  = var.public_subnet_ipv6_prefixes
  private_subnet_ipv6_prefixes = var.private_subnet_ipv6_prefixes
}


module "security_group" {
  source                     = "./security-groups"
  ec2_sg_name                = "SG for EC2 to enable HTTP and HTTPS"
  vpc_id                     = module.networking.infnet_proj_1_vpc_id
  public_subnet_cidr_block   = tolist(module.networking.infnet_proj_1_public_subnets)[0]
  alb_sg_name = "SG for alb to enable HTTP and HTTPS"
  ecs_sg_name = "SG for ECS to enable HTTP and HTTPS"
  ecs_alb_sg_name = "SG for ECS ALB to allow access to ECS instances from ALB"
}

module "launch_template" {
  source        = "./launch-template"
  ec2_ami_id    = var.ec2_ami_id
  ec2_security_group_id = module.security_group.sg_ec2 
 
}

module "auto-scaling" {
  source = "./auto-scaling"
  launch_template_id = module.launch_template.app_infnet_proj_1_launch_template_id
  asg_min_size = 1
  asg_max_size = 2
  asg_desired_capacity = 2
  private_subnet_ids_for_asg   = tolist(module.networking.infnet_proj_1_private_subnets)
  target_group_arns = [module.lb_target_group.infnet_proj_1_lb_target_group_arn]
}

module "lb_target_group" {
  source                   = "./load-balancer-target-group"
  lb_target_group_name     = "infnet-proj-1-lb-target-group"
  lb_target_group_port     = 80
  lb_target_group_protocol = "HTTP"
  vpc_id                   = module.networking.infnet_proj_1_vpc_id
  ecs_lb_target_group_name     = "infnet-lb-ecs-target-group"
  ecs_lb_target_group_port     = 80
  ecs_lb_target_group_protocol = "HTTP"
}

module "alb" {
  source                    = "./load-balancer"
  lb_name                   = "infnet-proj-1-alb"
  is_external               = false
  lb_type                   = "application"
  sg_enable_ssh_https       = module.security_group.sg_alb
  subnet_ids                = tolist(module.networking.infnet_proj_1_public_subnets)
  tag_name                  = "infnet-proj-1-alb"
  lb_target_group_arn       = module.lb_target_group.infnet_proj_1_lb_target_group_arn
  lb_listner_port           = 80
  lb_listner_protocol       = "HTTP"
  lb_listner_default_action = "forward"
  lb_target_group_attachment_port = 80
}

module "s3" {
  source = "./s3"
  bucket_name = "infnet-aws-compute-project-website-bucket"

} 

  module "ecr" {
  source = "./ecr"
  
  repository_name = "infnet-proj-1-repository"
}


module "codecommit" {
  source = "./codecommit"
  repository_name = "infnet-app-repo"
}

module "codebuild" {
  source = "./codebuild"
  ecr_repository_url   = module.ecr.repository_url
  codecommit_clone_url = module.codecommit.clone_url_http
}

module "ecs" {
  source = "./ECS"
  
  vpc_id               = module.networking.infnet_proj_1_vpc_id
  private_subnet_ids   = module.networking.infnet_proj_1_private_subnets
  target_group_arn     = module.lb_target_group.infnet_proj_1_lb_ecs_target_group_arn
  security_group_ids = module.security_group.sg_ecs
  ecr_repository_url = module.ecr.repository_url

  depends_on = [module.ecr, module.codebuild, module.codecommit]

   } 






