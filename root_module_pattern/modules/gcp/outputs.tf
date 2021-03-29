output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Primary Cluster Name"
}

output "vpc_name" {
  value       = google_compute_network.vpc.name
  description = "GCP VPC Name"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "GCP Subnetwork Name"
}
