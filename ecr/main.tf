variable "repository_name" {}

resource "aws_ecr_repository" "infnet_repository" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "infnet-proj-1-repository"
  }
}

output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.infnet_repository.repository_url
}

output "repository_arn" {
  description = "The ARN of the repository"
  value       = aws_ecr_repository.infnet_repository.arn
}