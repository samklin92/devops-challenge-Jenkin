terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  aws_region           = var.aws_region
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  private_subnets    = module.vpc.private_subnet_ids
  node_instance_type = var.eks_node_instance_type
  node_min           = var.eks_node_min
  node_max           = var.eks_node_max
  node_desired       = var.eks_node_desired
}

module "jenkins" {
  source           = "./modules/jenkins"
  project_name     = var.project_name
  public_subnet_id = module.vpc.public_subnet_ids[0]
  instance_type    = var.jenkins_instance_type
  my_ip            = var.my_ip
  ecr_repo_url     = module.ecr.repository_url
  eks_cluster_name = module.eks.cluster_name
  aws_region       = var.aws_region
}
