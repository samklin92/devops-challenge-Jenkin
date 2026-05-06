output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "jenkins_public_ip" {
  value = module.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${module.jenkins.public_ip}:8080"
}
