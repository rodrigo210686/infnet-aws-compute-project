variable "project_name" { default = "infnet-proj-1-build" }
variable "ecr_repository_url" {}
variable "codecommit_clone_url" {}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents",
          "ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability","ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage","ecr:PutImage","ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull","codecommit:GetRepository","codecommit:GetBranch","codecommit:GetCommit"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["sts:GetServiceBearerToken"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "app_build" {
  name         = var.project_name
  service_role = aws_iam_role.codebuild_role.arn

  artifacts { type = "NO_ARTIFACTS" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    privileged_mode            = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = var.ecr_repository_url
    }
  }

  source {
    type     = "CODECOMMIT"
    location = var.codecommit_clone_url
    buildspec = file("./codebuild/buildspec.yml")
  }
}

output "codebuild_project_name" {
  value = aws_codebuild_project.app_build.name
}