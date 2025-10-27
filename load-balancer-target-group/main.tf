variable "lb_target_group_name" {}
variable "lb_target_group_port" {}
variable "lb_target_group_protocol" {}
variable "ecs_lb_target_group_name" {}
variable "ecs_lb_target_group_port" {}
variable "ecs_lb_target_group_protocol" {}
variable "vpc_id" {}




resource "aws_lb_target_group" "infnet_proj_1_lb_target_group" {
  name     = var.lb_target_group_name
  port     = var.lb_target_group_port
  protocol = var.lb_target_group_protocol
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = 80
    healthy_threshold = 6
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

##TG for ECS instances
resource "aws_lb_target_group" "infnet_proj_1_lb_ecs_target_group" {
  name     = var.ecs_lb_target_group_name
  port     = var.ecs_lb_target_group_port
  protocol = var.ecs_lb_target_group_protocol
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = 80
    healthy_threshold = 6
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

output "infnet_proj_1_lb_target_group_arn" {
  value = aws_lb_target_group.infnet_proj_1_lb_target_group.arn
}

 output "infnet_proj_1_lb_ecs_target_group_arn" {
   value = aws_lb_target_group.infnet_proj_1_lb_ecs_target_group.arn 
  
 }