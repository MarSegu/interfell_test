data "azuredevops_project" "existing_project" {
  name = "ing_mario_implementations"
}

resource "azuredevops_build_definition" "terraform_pipeline" {
  project_id = data.azuredevops_project.existing_project.id
  name       = "Terraform Pipeline"
  
  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.interfell_test_Repo.id
    branch_name = "refs/heads/main"
    yml_path    = "azure-pipelines.yml" 
  }
}

resource "azuredevops_variable_group" "aws_variables" {
  project_id = azuredevops_project.example_project.id
  name       = "AWS_Variables"

  variable {
    name  = "AWS_ACCESS_KEY_ID"
    value = var.aws_access_key_id
    secret_value = true
  }

  variable {
    name  = "AWS_SECRET_ACCESS_KEY"
    value = var.aws_secret_access_key
    secret_value = true
  }

  variable {
    name  = "AWS_REGION"
    value = "us-east-1"
  }
}
