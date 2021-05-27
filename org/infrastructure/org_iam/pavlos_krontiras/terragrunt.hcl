# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
#locals {
#}

terraform {
  source = "../../../../modules//org-permissions/"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}
  inputs = {
    org_iam_permissions   = [
      "roles/billing.admin",
      "roles/compute.networkAdmin",
      "roles/compute.xpnAdmin",
      "roles/compute.networkViewer",
      "roles/iam.securityAdmin",
      "roles/iam.serviceAccountAdmin",
      "roles/logging.configWriter",
      "roles/orgpolicy.policyAdmin",
      "roles/resourcemanager.organizationViewer",
      "roles/bigquery.admin",
      "roles/resourcemanager.projectCreator",
      "roles/serviceusage.serviceUsageAdmin",
      "roles/source.admin",
      "roles/resourcemanager.organizationAdmin",
      "roles/storage.objectAdmin",
      "roles/vmmigration.viewer",
      "roles/cloudbuild.builds.editor",
      "roles/compute.admin"
    ]
  member_name = "pavlos.krontiras@appsbroker.com"
  member_type = "user"
  }
