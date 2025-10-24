variable "asg_max_size" {}
variable "asg_min_size" {}
variable "asg_desired_capacity" {}
variable "launch_template_id" {}
variable "private_subnet_ids_for_asg" {}
variable "target_group_arns" {
  type    = list(string)
  default = []
}

resource "aws_autoscaling_group" "app_infnet_proj_1_asg" {
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids_for_asg
  health_check_type         = "ELB"
  health_check_grace_period = 300
  

  target_group_arns = var.target_group_arns
  

  tag {
    key                 = "Name"
    value               = "infnet-proj-1-asg-instance"
    propagate_at_launch = true
  }
  
}
