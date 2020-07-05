# Launch Configuration
# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  extra_args           = " --kubelet-extra-args \"${var.kubelet_extra_args}\""
  extra_args_string    = "${var.kubelet_extra_args != "" ? local.extra_args : ""}"
  bootstrap_extra_args = "${var.enable_docker_bridge ? "--enable-docker-bridge true" : ""}"

  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh "${var.cluster_name}" --use-max-pods true --b64-cluster-ca "${var.cluster_ca_data}" ${local.bootstrap_extra_args} --apiserver-endpoint "${var.cluster_endpoint}"${local.extra_args_string}
USERDATA
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ops_${var.environment}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2b8WkXWdWfA/mZxHOba3DlibFVIYT76I5lC2mNxqWVcPY27iXYk1fJWAzskjb/ZJwAC+6US16QFhaU2+aDWF8MBU0bdQdcx2M/+ik8BZNcPfRkVkn9Wa5oGtk2QQQL1cxKzadKO7he/LZZfqRr7R5JRlNKyjiXIEAHU8GY+Jm6jMNG3pNLZh1AMA1XhrokgZ1qCFeCntrA+2MFodYVVdKNA1Ethi6zN/sqvp9Cuv2breXsNvUKWBtQgja7riEYtueSOmrGirvSf7TEDU2qpPXo4tayHtePNL6xNoeY2kBl19cdrwKyvV/1Fl/xd4y283a2UpWjPdn9fodHU7ph/OHP/HXu6TDkcmAFH750rIiccq+DJimkHH4cvOGbTNqDNBc1+4/+7Tgb8g++IHBfBJhi555S5rScWeq5klYU/BOMrRa7ybE0RILG7kn3gIUD+yXzpXR+CSqmRGcMSTvoUilMip6YkZkmacduJz3aCOMBobeem1amkq+bOltqfK948IPVkDuHJhgPMlR4oRFpripFEryvXSzYGQwuhV6qS4z2xLb9Uc/zbcf4Yiip6MukT9n9K1Q9qUitmJLSO6EiFYPD+JN1ulAQFuBRGkgJDtte5cfIqbw8wm//g0SHEsS6AVIkjnE/O0Au9fbH33Z+RDZBbp7lEn8tjbvIJpyZWOP7Q== moshec@woo.io"
}

resource "aws_launch_configuration" "node" {
  associate_public_ip_address = false
  iam_instance_profile        = "${var.node_instance_profile_name}"
  image_id                    = "${var.eks_node_ami_id}"
  instance_type               = "${var.node_instance_type}"
  name_prefix                 = "${var.cluster_name}-${var.node_pool_name}-"
  security_groups             = ["${var.node_sg_id}", "${aws_security_group.node.id}"]
  user_data_base64            = "${base64encode(local.node-userdata)}"
  key_name                    = "${aws_key_pair.key_pair.key_name}"
  spot_price                  = "${var.node_spot_price}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "${var.node_instance_root_volume_size}"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ASG
resource "aws_autoscaling_group" "node" {
  desired_capacity     = "${var.node_pool_desired_size}"
  launch_configuration = "${aws_launch_configuration.node.id}"
  max_size             = "${var.node_pool_max_size}"
  min_size             = "${var.node_pool_min_size}"
  name                 = "${var.cluster_name}-${var.node_pool_name}"
  vpc_zone_identifier  = var.node_subnets
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]
  enabled_metrics      = ["GroupTerminatingInstances", "GroupMaxSize", "GroupDesiredCapacity", "GroupPendingInstances", "GroupInServiceInstances", "GroupMinSize", "GroupTotalInstances", "GroupStandbyInstances"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-${var.node_pool_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "EKSCluster"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "EKSNodePool"
    value               = "${var.node_pool_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "scaledown" {
  count                  = "${var.enable_scheduled_action == "true" ? 1 : 0}"
  scheduled_action_name  = "${var.cluster_name}-nightly_scaledown"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "${var.scaledown_schedule}"
  autoscaling_group_name = "${aws_autoscaling_group.node.name}"
}

resource "aws_autoscaling_schedule" "scale_up" {
  count                  = "${var.enable_scheduled_action == "true" ? 1 : 0}"
  scheduled_action_name  = "${var.cluster_name}-nightly_scaleup"
  min_size               = "${var.node_pool_min_size}"
  max_size               = "${var.node_pool_max_size}"
  desired_capacity       = "${var.node_pool_desired_size}"
  recurrence             = "${var.scaleup_schedule}"
  autoscaling_group_name = "${aws_autoscaling_group.node.name}"
}

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-${var.node_pool_name}"
  description = "K8s ${var.node_pool_name} security group"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name        = "${var.cluster_name}-${var.node_pool_name}"
    Environment = "${var.environment}"
    EKSNodePool = "${var.node_pool_name}"
    EKSCluster  = "${var.cluster_name}"
  }
}
