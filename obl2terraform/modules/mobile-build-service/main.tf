provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "bucket-para-el-pipeline-del-obligatorio2"
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codebuild_attach" {
  name       = "codebuild-role-policy"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_repository_name
}

resource "aws_codebuild_project" "docker_build" {
  name          = "docker-build-project"
  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github_owner}/${var.github_repo}.git"
    buildspec       = "mobile-build-service/buildspec.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = aws_iam_role.codebuild_role.arn
}

resource "aws_codepipeline" "pipeline" {
  name     = "mobile-build-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token  
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Docker_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.docker_build.name
      }
    }
  }
}


resource "aws_iam_policy" "codepipeline_policy" {
  name        = "CodePipelineFullAccessPolicy"
  description = "Permisos completos para CodePipeline"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "codepipeline:CreatePipeline",
          "codepipeline:GetPipeline",
          "codepipeline:DeletePipeline",
          "codepipeline:UpdatePipeline",
          "codepipeline:StartPipelineExecution",
          "codepipeline:ListPipelines"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "codepipeline_policy_attach" {
  user       = "SantiagoTerraform" //usuario
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRFullAccessPolicy"
  description = "Permisos completos para ECR con permisos adicionales"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:ListTagsForResource"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ecr_policy_attach" {
  user       = "SantiagoTerraform" //usuario
  policy_arn = aws_iam_policy.ecr_policy.arn
}