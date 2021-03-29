output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Primary Cluster Name"
}
