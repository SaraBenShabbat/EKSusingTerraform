data "aws_caller_identity" "current" {}

# Cluster IAM role & policy attachments
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-master"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster.name}"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster.name}"
}

# Node IAM role & policy attachments
resource "aws_iam_role" "cluster-node" {
  name = "${var.cluster_name}-cluster-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.cluster-node.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.cluster-node.name}"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.cluster-node.name}"
}

resource "aws_iam_instance_profile" "cluster-node" {
  name = "${aws_iam_role.cluster-node.name}"
  role = "${aws_iam_role.cluster-node.name}"
}

# Role for cluster admin
resource "aws_iam_role" "cluster-admin-role" {
  name = "${var.cluster_name}-cluster-admin"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cluster-admin-policy" {
  name        = "${var.cluster_name}-cluster-admin-assume"
  description = "${var.cluster_name}-cluster-admin-assume policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.cluster-admin-role.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_group" "cluster-admin-group" {
  name = "${var.cluster_name}-cluster-admin"
  path = "/kubernetes/"
}

resource "aws_iam_group_policy_attachment" "cluster-admin-policy-attachment" {
  group      = "${aws_iam_group.cluster-admin-group.name}"
  policy_arn = "${aws_iam_policy.cluster-admin-policy.arn}"
}

# Role for cluster dev
resource "aws_iam_role" "cluster-dev-role" {
  name = "${var.cluster_name}-cluster-dev"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cluster-dev-policy" {
  name        = "${var.cluster_name}-cluster-dev-assume"
  description = "${var.cluster_name}-cluster-dev-assume policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.cluster-dev-role.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_group" "cluster-dev-group" {
  name = "${var.cluster_name}-cluster-dev"
  path = "/kubernetes/"
}

resource "aws_iam_group_policy_attachment" "cluster-dev-policy-attachment" {
  group      = "${aws_iam_group.cluster-dev-group.name}"
  policy_arn = "${aws_iam_policy.cluster-dev-policy.arn}"
}

# Role for cluster read
resource "aws_iam_role" "cluster-read-role" {
  name = "${var.cluster_name}-cluster-read"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "cluster-read-policy" {
  name        = "${var.cluster_name}-cluster-read-assume"
  description = "${var.cluster_name}-cluster-read-assume policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.cluster-read-role.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_group" "cluster-read-group" {
  name = "${var.cluster_name}-cluster-read"
  path = "/kubernetes/"
}

resource "aws_iam_group_policy_attachment" "cluster-read-policy-attachment" {
  group      = "${aws_iam_group.cluster-read-group.name}"
  policy_arn = "${aws_iam_policy.cluster-read-policy.arn}"
}

# Allow nodes to assume other roles
resource "aws_iam_policy" "kube2iam-policy" {
  name        = "${var.cluster_name}-kube2iam"
  description = "kube2iam policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "kube2iam-attachment" {
  role       = "${aws_iam_role.cluster-node.name}"
  policy_arn = "${aws_iam_policy.kube2iam-policy.arn}"
}

