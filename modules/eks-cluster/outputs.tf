# Cluster ID
output "cluster_id" {
  value = "${aws_eks_cluster.cluster.id}"
}

# Cluster Name
output "cluster_name" {
  value = "${aws_eks_cluster.cluster.name}"
}

# Cluster Endpoint
output "cluster_endpoint" {
  value = "${aws_eks_cluster.cluster.endpoint}"
}

# Cluster CA Data
output "cluster_ca_data" {
  value = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
}

# Cluster SG ID
output "cluster_sg_id" {
  value = "${aws_security_group.cluster-masters.id}"
}

# Node SG ID
output "node_sg_id" {
  value = "${aws_security_group.cluster-nodes.id}"
}

# Output kubeconfig for the cluster
output "kubeconfig" {
  value = "${local.kubeconfig}"
}

# Node Instance Profile
output "node_instance_profile_name" {
  value = "${aws_iam_instance_profile.cluster-node.name}"
}

# Node IAM Role ARN
output "node_iam_role_arn" {
  value = "${aws_iam_role.cluster-node.arn}"
}

# Config map to attach nodes to cluster
output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}
