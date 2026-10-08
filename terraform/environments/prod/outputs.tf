output "vpc_id" {
  description = "Platform VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_node_role_arn" {
  description = "EKS worker node IAM role ARN"
  value       = module.eks.node_role_arn
}

output "eks_oidc_provider_arn" {
  description = "EKS IAM OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  value       = module.eks.oidc_issuer_url
}

output "eks_vpc_cni_role_arn" {
  description = "VPC CNI IAM role ARN"
  value       = module.eks.vpc_cni_role_arn
}

output "eks_ebs_csi_role_arn" {
  description = "EBS CSI IAM role ARN"
  value       = module.eks.ebs_csi_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by the AWS Load Balancer Controller"
  value       = module.eks.aws_load_balancer_controller_role_arn
}
