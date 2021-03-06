output "subnets" {
  value       = google_compute_subnetwork.sub_network
  description = "The created subnets resources"
}

output "subnet_ids" {
  value       = values(google_compute_subnetwork.sub_network)[*].id
  description = "The created subnets resources"
}
