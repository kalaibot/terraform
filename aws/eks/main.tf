provider "aws" {
  version = "2.6.0"
  region = "${local.aws_region}"
}

locals {
  # pick the instance type of your choice
  worker_instance_type       = "m5.xlarge"
  # create ssh-key pair in aws in specific region
  ssh_key_pair               = "kalai-qa-us-west-2"
  # create the vpc & get the vpc id or get the default vpc id
  vpc_id                     = "vpc-020309fcd1676c23c"
  # specify the region where the cluster should reside
  aws_region                 = "us-west-2"
  # Name the eks cluster of your choice
  cluster_name               = "site-test"
  # Name the worker group name of your choice
  instance_worker_group_name = "airflow"
  # Get the username from aws IAM
  username_iam               = "kalai.arasan"
  # Get aws account id and username from aws IAM - fill it up below
  user_arn                   = "arn:aws:iam::730036231311:user/kalai.arasan"
}

# Cluster will be placed in these subnets:
variable "cluster_subnet" {
    default =[
        "10.10.48.0/20",
        "10.10.16.0/20",
        "10.10.80.0/20",
    ]
}

data "aws_subnet_ids" "cluster_subnet" {
    vpc_id = "${local.vpc_id}"
    filter {
        name   = "cidr-block"
        values = "${var.cluster_subnet}"
    }
}

module "eks_cluster_1" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "4.0.2"

  cluster_name    = "${local.cluster_name}"
  cluster_version = "1.14"

  vpc_id          = "${local.vpc_id}"
  subnets         = "${data.aws_subnet_ids.cluster_subnet.ids}"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  worker_additional_security_group_ids = []

  worker_ami_name_filter    = "v20190927"

  worker_group_count        = "1"
  worker_groups = [
    {
      name                  = "${local.instance_worker_group_name}"
      instance_type         = "${local.worker_instance_type}"
      asg_desired_capacity  = "2"
      asg_min_size          = "2"
      asg_max_size          = "8"
      key_name              = "${local.ssh_key_pair}"
      autoscaling_enabled   = true
      protect_from_scale_in = true
    }
  ]

  map_users_count = 1
  map_users = [
    # ADMINS
    {
      user_arn = "${local.user_arn}"
      username = "${local.username_iam}"
      group    = "system:masters"
    },
  ]
}
