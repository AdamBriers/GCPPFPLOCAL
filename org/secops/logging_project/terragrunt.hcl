# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
#locals {
#}

terraform {
  source = "../../../modules//project/"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}

dependency "folder" {
  config_path = "../"

  # Configure mock outputs for the terraform commands that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    folder_id = "folder-not-created-yet"
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {

  project_name       = "gc-a-prj-secopslogs-0001"
  folder_id          = dependency.folder.outputs.folder_created ## SecOps folder id
  is_service_project = false
  # host_project_id - Taken from the hard coded value in the 'org/org.tfvars' file

  labels = {
    application      = "secops_logging_project"
    businessunit     = "homes"
    costcentre       = "90imt"
    createdby        = "appsbroker"
    department       = "it"
    disasterrecovery = "no"
    environment      = "secops"
    contact          = "appsbroker"
  }
}