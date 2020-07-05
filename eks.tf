module "eks_cluster" {
  source       = "./modules/eks-cluster"
  cluster_name = "${var.eks-name}"
  vpc_id       = "${module.vpc.vpc_id}"
  cluster_subnets      =  "${module.vpc.private_subnets}"
  kubeconfig_s3_bucket = "vatbox-eks-terraform"
}

module "node_pool_1" {
  source                     = "./modules/eks-cluster-nodes"
  environment                = "${var.eks-name}"
  cluster_name               = "${var.eks-name}"
  cluster_endpoint           = "${module.eks_cluster.cluster_endpoint}"
  cluster_ca_data            = "${module.eks_cluster.cluster_ca_data}"
  node_instance_type         = "r5.xlarge"
  node_pool_desired_size     = "16"
  node_pool_min_size         = "16"
  node_pool_max_size         = "16"
  node_pool_name             = "node_pool_1"
  vpc_id                     = "${module.vpc.vpc_id}"
  cluster_sg_id              = "${module.eks_cluster.cluster_sg_id}"
  node_sg_id                 = "${module.eks_cluster.node_sg_id}"
  node_subnets               = "${module.vpc.private_subnets}"
  node_instance_profile_name = "${module.eks_cluster.node_instance_profile_name}"
  eks_node_ami_id            = "ami-080af0c6edf8a81d7"
}
