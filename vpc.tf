variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "var_access_key" {
  description = "AWS_ACCESS_KEY_ID"
  type        = string
  default = "AWS_ACCESS_KEY_ID"
  sensitive = true
}

variable "var_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY"
  type        = string
  default = "AWS_SECRET_ACCESS_KEY"
  sensitive = true
}

provider "aws" {
  region = "us-east-1"
  access_key = var.var_access_key
  secret_key = var.var_secret_access_key

}

locals {
  tagEnv = "${terraform.workspace}-ifedorov" 
  NameBucket = "ifedorov"
  clusterName =  "${terraform.workspace}-ifedorov-project-${random_string.suffix.result}"
  namePrivateSN = "${terraform.workspace}-ifedorov-SN-private" 
  namePublicSN  = "${terraform.workspace}-ifedorov-SN-public" 
}
data "aws_availability_zones" "available" {}

terraform {
  backend "s3" {
    bucket = "ifedorov"
    key = "ClusterEKS_IF.tfstate"
    region = "us-east-1"
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = local.tagEnv
  cidr                 = "172.110.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.110.0.0/19", "172.110.32.0/19"]
  public_subnets       = ["172.110.64.0/19", "172.110.96.0/19"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.clusterName}" = local.tagEnv
    Enviroment = local.tagEnv
    Description = local.NameBucket
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.clusterName}" = local.namePublicSN
    "kubernetes.io/role/elb"                      = "1"
    Enviroment = local.tagEnv
    Description = local.NameBucket
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.clusterName}" = local.namePrivateSN
    "kubernetes.io/role/internal-elb"             = "1"
    Enviroment = local.tagEnv
    Description = local.NameBucket
  }
}
