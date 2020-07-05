

provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"


  name = "eks-test-vpc"

  cidr = "10.10.0.0/16"

  azs              = ["us-east-2a","us-east-2b"]
  private_subnets  = ["10.10.2.0/24", "10.10.1.0/24"]
  public_subnets   = ["10.10.11.0/24", "10.10.12.0/24"]


  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = false

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = false
  enable_dns_hostnames     = true

  enable_dhcp_options      = true
  dhcp_options_domain_name = "ec2.internal"

  tags = {
    Owner                                         = "develeap"
    Environment                                   = "test"
    Name                                          = "eks-test-vpc"
    "kubernetes.io/cluster/eks-test" = "owned"
  }

}
