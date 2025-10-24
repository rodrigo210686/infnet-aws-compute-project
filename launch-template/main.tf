variable "ec2_ami_id" {}
variable "ec2_security_group_id" {}

resource "aws_launch_template" "app_infnet_proj_1_launch_template" {
  name_prefix   = "app-infnet-proj-1-"
  image_id      = var.ec2_ami_id
  instance_type = "t2.micro"

  vpc_security_group_ids = [var.ec2_security_group_id]

  #user_data = base64encode(templatefile("./template/ec2_install_apache.sh", {}))
  user_data = base64encode(file("./template/ec2_install_apache.sh"))
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app-infnet-proj-1-ec2-instance"
    }
  }
}

output "app_infnet_proj_1_launch_template_id" {
  value = aws_launch_template.app_infnet_proj_1_launch_template.id
}
  