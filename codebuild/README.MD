To trigger the build:

```sh
# Get the project name
export PROJECT_NAME=$(terraform output -raw codebuild_project_name)

# Start the build
aws codebuild start-build --project-name $PROJECT_NAME
```

This setup will:

Create a CodeBuild project with necessary IAM roles
Use buildspec.yml to define build steps
Build your Docker image
Push it to your ECR repository

Log into ECR
Build your Docker image
Tag it with 'latest' and a commit hash
Push both tags to ECR
Make sure to run: