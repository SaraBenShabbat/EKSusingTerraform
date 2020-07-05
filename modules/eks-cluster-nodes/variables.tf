variable "eks_node_ami_id" {
  description = "The AMI ID of the EKS node image, published by AWS"
  default     = "ami-0d3998d69ebe9b214"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
}

variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
}

variable "cluster_ca_data" {
  description = "The CA data for the cluster"
}

variable "environment" {
  description = "The name of the environment"
}

variable "node_pool_name" {
  default     = "node_pool"
  description = "The name of the node pool"
}

variable "vpc_id" {
  description = "VPC ID to launch the cluster within"
}

variable "node_subnets" {
  type        = list
  description = "List of subnets for the nodes to be launched in"
}

variable "cluster_sg_id" {
  description = "SG ID for the cluster masters, to enable connectivity"
}

variable "node_sg_id" {
  description = "SG ID for the cluster nodes, to enable connectivity"
}

variable "node_instance_profile_name" {
  description = "Instance profile for the nodes to be launched with"
}

variable "node_instance_type" {
  default     = "m5.xlarge"
  description = "Node instance type"
}

variable "node_spot_price" {
  default     = ""
  description = "Node spot price "
}

variable "node_pool_min_size" {
  default     = "3"
  description = "Node pool ASG minimum size"
}

variable "node_pool_max_size" {
  default     = "3"
  description = "Node pool ASG maximum size"
}

variable "node_pool_desired_size" {
  default     = "3"
  description = "Node pool ASG desired size"
}

variable "node_instance_root_volume_size" {
  description = "The size of the root volume for the node instances (default: 100)"
  default     = "100"
}

variable "kubelet_extra_args" {
  description = "Extra arguments to pass to the kubelet"
  default     = ""
}

variable "scaledown_schedule" {
  description = "Cron expression in UTC to scaledown the scaling group"
  default     = "00 19 * * *"
}

variable "scaleup_schedule" {
  description = "Cron expression in UTC to scaleup the scaling group"
  default     = "00 5 * * 0-5"
}

variable "enable_scheduled_action" {
  description = "Enable scheduled scaling actions"
  default     = "false"
}

variable "enable_docker_bridge" {
  description = "Enable docker bridge for docker in docker"
  default     = "false"
}
