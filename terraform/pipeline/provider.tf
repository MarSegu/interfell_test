provider "azuredevops" {
  org_service_url = "https://dev.azure.com/azure_devops_org"
  personal_access_token = var.azure_devops_pat
}
