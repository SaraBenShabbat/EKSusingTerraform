variable "cluster_name" {
  description = "The name of the EKS cluster"
}

variable "vpc_id" {
  description = "VPC ID to launch the cluster within"
}

variable "cluster_subnets" {
  type        = list
  description = "List of subnets to launch the cluster with"
}

variable "kubeconfig_s3_bucket" {
  description = "The name of the S3 bucket that stores kubeconfig"
}

variable "kubeconfig_s3_bucket_path" {
  description = "The path within the kubeconfig_s3_bucket to store kubeconfig in"
  default     = "kubeconfig"
}

variable "config-map-aws-auth_s3_bucket_path" {
  description = "The path within the kubeconfig_s3_bucket to store config-map-aws-auth in"
  default     = "config-map-aws-auth"
}

variable "k8s_version" {
  description = "Version of kubernetes to install"
  default     = "1.14"
}
