##############################################
# VARIABLES
##############################################

variable "vpc_id" {}
variable "target_group_arn" {}
variable "ecr_repository_url" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {}

##############################################
# IAM ROLES - ECS INSTANCE
##############################################

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Políticas obrigatórias para ECS EC2 Instances
resource "aws_iam_role_policy_attachment" "ecs_instance_ecs_service" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_managed" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInstanceRolePolicyForManagedInstances"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

##############################################
# IAM ROLES - ECS TASK EXECUTION ROLE
##############################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Políticas necessárias para execução de tarefas ECS
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecr_readonly" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

##############################################
# CUSTOM POLICY - AUTOSCALING MANAGEMENT
##############################################

resource "aws_iam_policy" "custom_autoscaling_service_role_policy" {
  name        = "CustomAutoScalingServiceRolePolicy"
  description = "Custom policy granting EC2, AutoScaling, ELB, and CloudWatch permissions for ECS instances."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2InstanceManagement"
        Effect = "Allow"
        Action = [
          "ec2:AttachClassicLinkVpc",
          "ec2:CancelSpotInstanceRequests",
          "ec2:CreateFleet",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:Describe*",
          "ec2:DetachClassicLinkVpc",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:ModifyInstanceAttribute",
          "ec2:RequestSpotInstances",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2InstanceProfileManagement"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ec2.amazonaws.com*"
          }
        }
      },
      {
        Sid    = "ELBManagement"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:Register*",
          "elasticloadbalancing:Deregister*",
          "elasticloadbalancing:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "CWManagement"
        Effect = "Allow"
        Action = [
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:PutMetricAlarm"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSManagement"
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = "*"
      },
      {
        Sid    = "SystemsManagerParameterManagement"
        Effect = "Allow"
        Action = ["ssm:GetParameters"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_custom_autoscaling" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = aws_iam_policy.custom_autoscaling_service_role_policy.arn
}

##############################################
# ECS CLUSTER
##############################################

resource "aws_ecs_cluster" "infnet_ecs_cluster" {
  name = "infnet-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "infnet-ecs-cluster"
  }
}

##############################################
# LAUNCH TEMPLATE (EC2 ECS OPTIMIZED)
##############################################

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-051685736c7b35f95"  # Amazon ECS-optimized AMI
  instance_type = "t3.medium"

  vpc_security_group_ids = [var.security_group_ids]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.infnet_ecs_cluster.name}" >> /etc/ecs/ecs.config;
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }
}

##############################################
# AUTO SCALING GROUP
##############################################

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 2

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

##############################################
# CAPACITY PROVIDER
##############################################

resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "infnet-ecs-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }

    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_cp" {
  cluster_name       = aws_ecs_cluster.infnet_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
    base              = 1
  }
}

##############################################
# TASK DEFINITION
##############################################

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "infnet-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "infnet-container"
      image     = "${var.ecr_repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

##############################################
# OUTPUTS
##############################################

output "ecs_cluster_id" {
  value = aws_ecs_cluster.infnet_ecs_cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.infnet_ecs_cluster.name
}
output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.ecs_task.arn
}