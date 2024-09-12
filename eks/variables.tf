# General Variables
variable "aws-region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
}

variable "env" {
  description = "The environment for the deployment (e.g., dev, prod)"
  type        = string
}

variable "cluster-name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "vpc-cidr-block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc-name" {
  description = "The name of the VPC"
  type        = string
}

variable "igw-name" {
  description = "The name of the Internet Gateway"
  type        = string
}

# Public Subnets
variable "pub-subnet-count" {
  description = "The number of public subnets"
  type        = number
}

variable "pub-cidr-block" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "pub-availability-zone" {
  description = "List of availability zones for the public subnets"
  type        = list(string)
}

variable "pub-sub-name" {
  description = "The name prefix for public subnets"
  type        = string
}

# Private Subnets
variable "pri-subnet-count" {
  description = "The number of private subnets"
  type        = number
}

variable "pri-cidr-block" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "pri-availability-zone" {
  description = "List of availability zones for the private subnets"
  type        = list(string)
}

variable "pri-sub-name" {
  description = "The name prefix for private subnets"
  type        = string
}

# Route Tables
variable "public-rt-name" {
  description = "The name of the public route table"
  type        = string
}

variable "private-rt-name" {
  description = "The name of the private route table"
  type        = string
}

# NAT Gateway and Elastic IP
variable "eip-name" {
  description = "The name of the Elastic IP resource"
  type        = string
}

variable "ngw-name" {
  description = "The name of the NAT Gateway"
  type        = string
}

# Security Group
variable "eks-sg" {
  description = "The security group for the EKS cluster"
  type        = string
}

# EKS Cluster
variable "is-eks-cluster-enabled" {
  description = "Flag to enable or disable the EKS cluster"
  type        = bool
}

variable "cluster-version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "endpoint-private-access" {
  description = "Flag to enable private access to the EKS cluster"
  type        = bool
}

variable "endpoint-public-access" {
  description = "Flag to enable public access to the EKS cluster"
  type        = bool
}

# EC2 Instances (On-Demand and Spot)
variable "ondemand_instance_types" {
  description = "List of instance types for on-demand EC2 instances"
  default     = ["t3a.medium"]
  type        = list(string)
}

variable "spot_instance_types" {
  description = "List of instance types for spot EC2 instances"
  type        = list(string)
}

# Auto-scaling for On-Demand Instances
variable "desired_capacity_on_demand" {
  description = "Desired number of on-demand instances in the node group"
  type        = number
}

variable "min_capacity_on_demand" {
  description = "Minimum number of on-demand instances in the node group"
  type        = number
}

variable "max_capacity_on_demand" {
  description = "Maximum number of on-demand instances in the node group"
  type        = number
}

# Auto-scaling for Spot Instances
variable "desired_capacity_spot" {
  description = "Desired number of spot instances in the node group"
  type        = number
}

variable "min_capacity_spot" {
  description = "Minimum number of spot instances in the node group"
  type        = number
}

variable "max_capacity_spot" {
  description = "Maximum number of spot instances in the node group"
  type        = number
}

# EKS Add-ons
variable "addons" {
  description = "List of EKS add-ons to be installed, including name and version"
  type = list(object({
    name    = string
    version = string
  }))
}