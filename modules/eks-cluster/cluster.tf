# Inspired by: https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html

# Master security group & rules
resource "aws_security_group" "cluster-masters" {
  name        = "${var.cluster_name}-masters"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "Name", "${var.cluster_name}-masters",
    )
  }"
}

# Workers security group & rules
resource "aws_security_group" "cluster-nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "Name", "${var.cluster_name}-nodes",
      "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "cluster-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.cluster-nodes.id}"
  source_security_group_id = "${aws_security_group.cluster-nodes.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster-nodes.id}"
  source_security_group_id = "${aws_security_group.cluster-masters.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster-masters.id}"
  source_security_group_id = "${aws_security_group.cluster-nodes.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-ingress-cluster-https" {
  description              = "Allow the cluster API server to communicate with nodes"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster-nodes.id}"
  source_security_group_id = "${aws_security_group.cluster-masters.id}"
  to_port                  = 443
  type                     = "ingress"
}

# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.cluster.arn}"
  version  = "${var.k8s_version}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster-masters.id}"]
    subnet_ids         = var.cluster_subnets
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]
}

# Upload kubeconfig
locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: ${aws_eks_cluster.cluster.name}-terraform
  name: ${aws_eks_cluster.cluster.name}-terraform
- context:
    cluster: kubernetes
    user: ${aws_eks_cluster.cluster.name}-admin
  name: ${aws_eks_cluster.cluster.name}-admin
- context:
    cluster: kubernetes
    user: ${aws_eks_cluster.cluster.name}-dev
  name: ${aws_eks_cluster.cluster.name}-dev
- context:
    cluster: kubernetes
    user: ${aws_eks_cluster.cluster.name}-read
  name: ${aws_eks_cluster.cluster.name}-read
current-context: ${aws_eks_cluster.cluster.name}-read
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.cluster.name}-terraform
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.cluster.name}"
- name: ${aws_eks_cluster.cluster.name}-admin
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.cluster.name}"
        - "-r"
        - "${aws_iam_role.cluster-admin-role.arn}"
- name: ${aws_eks_cluster.cluster.name}-dev
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.cluster.name}"
        - "-r"
        - "${aws_iam_role.cluster-dev-role.arn}"
- name: ${aws_eks_cluster.cluster.name}-read
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.cluster.name}"
        - "-r"
        - "${aws_iam_role.cluster-read-role.arn}"
KUBECONFIG
}

resource "aws_s3_bucket_object" "kubeconfig" {
  bucket  = "${var.kubeconfig_s3_bucket}"
  key     = "${var.kubeconfig_s3_bucket_path}/config-${aws_eks_cluster.cluster.name}"
  content = "${local.kubeconfig}"
}

# Upload config map for nodes
locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.cluster-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${aws_iam_role.cluster-admin-role.arn}
      username: cluster-admin:{{SessionName}}
      groups:
        - system:masters
        - cluster-admin
    - rolearn: ${aws_iam_role.cluster-dev-role.arn}
      username: cluster-dev:{{SessionName}}
      groups:
        - cluster-dev
    - rolearn: ${aws_iam_role.cluster-read-role.arn}
      username: cluster-read:{{SessionName}}
      groups:
        - cluster-read
CONFIGMAPAWSAUTH
}

resource "aws_s3_bucket_object" "config-map-aws-auth" {
  bucket  = "${var.kubeconfig_s3_bucket}"
  key     = "${var.config-map-aws-auth_s3_bucket_path}/${aws_eks_cluster.cluster.name}/config-map-aws-auth.yaml"
  content = "${local.config-map-aws-auth}"
}
