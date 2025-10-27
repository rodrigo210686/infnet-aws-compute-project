variable "repository_name" {
  type    = string
  default = "infnet-app-repo"
}
variable "description" {
  type    = string
  default = "Repo for infnet app (built by CodeBuild)"
}

resource "aws_codecommit_repository" "repo" {
  repository_name = var.repository_name
  description     = var.description
}

output "repository_name" {
  value = aws_codecommit_repository.repo.repository_name
}

output "clone_url_http" {
  value = aws_codecommit_repository.repo.clone_url_http
}

output "clone_url_ssh" {
  value = aws_codecommit_repository.repo.clone_url_ssh
}