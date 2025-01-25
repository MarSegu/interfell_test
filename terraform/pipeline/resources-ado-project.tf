resource "azuredevops_git_repository" "interfell_test_Repo" {
  project_id = data.azuredevops_project.existing_project.id
  name       = "interfell_test"
  initialization {
    init_type = "Clean"
  }
}