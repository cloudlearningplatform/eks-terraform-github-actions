# Defining local variables, where the cluster name is taken from the input variable "cluster-name"
locals {
  cluster_name = var.cluster-name
}

# Generating a random integer that will be used as a suffix for unique resource naming
resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

# Creating an IAM role for the EKS cluster, with an assume role policy allowing the EKS service to assume the role
resource "aws_iam_role" "eks-cluster-role" {
  count = var.is_eks_role_enabled ? 1 : 0  # Conditional creation based on whether the EKS role is enabled
  name  = "${local.cluster_name}-role-${random_integer.random_suffix.result}"  # Dynamically names the role using the cluster name and random suffix

  # Defining the assume role policy for EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attaching the AmazonEKSClusterPolicy to the created IAM role, allowing the EKS service to manage resources on the cluster
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  count      = var.is_eks_role_enabled ? 1 : 0  # Conditional creation based on whether the EKS role is enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # Using the predefined Amazon EKS policy
  role       = aws_iam_role.eks-cluster-role[count.index].name  # Attaching the policy to the created role
}

# Creating an IAM role for the EKS node group, with an assume role policy allowing EC2 to assume the role
resource "aws_iam_role" "eks-nodegroup-role" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0  # Conditional creation based on whether the node group role is enabled
  name  = "${local.cluster_name}-nodegroup-role-${random_integer.random_suffix.result}"  # Dynamically names the role using the cluster name and random suffix

  # Defining the assume role policy for EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attaching the AmazonEKSWorkerNodePolicy to the node group IAM role, allowing EC2 nodes to perform worker node operations
resource "aws_iam_role_policy_attachment" "eks-AmazonWorkerNodePolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0  # Conditional creation based on whether the node group role is enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  # Attaching worker node policy
  role       = aws_iam_role.eks-nodegroup-role[count.index].name  # Linking the policy to the node group role
}

# Attaching the AmazonEKS_CNI_Policy to the node group IAM role, enabling network interface operations for the EKS cluster
resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0  # Conditional creation based on whether the node group role is enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Attaching CNI policy for network operations
  role       = aws_iam_role.eks-nodegroup-role[count.index].name  # Linking the policy to the node group role
}

# Attaching the AmazonEC2ContainerRegistryReadOnly policy to the node group IAM role, granting read-only access to ECR repositories
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0  # Conditional creation based on whether the node group role is enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  # Attaching ECR read-only policy
  role       = aws_iam_role.eks-nodegroup-role[count.index].name  # Linking the policy to the node group role
}

# Attaching the AmazonEBSCSIDriverPolicy to the node group IAM role, enabling EBS volume operations
resource "aws_iam_role_policy_attachment" "eks-AmazonEBSCSIDriverPolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0  # Conditional creation based on whether the node group role is enabled
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"  # Attaching EBS CSI driver policy
  role       = aws_iam_role.eks-nodegroup-role[count.index].name  # Linking the policy to the node group role
}

# OIDC: Creating an IAM role for OpenID Connect (OIDC) integration, used for fine-grained access control to AWS resources
resource "aws_iam_role" "eks_oidc" {
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json  # Using the predefined OIDC assume role policy
  name               = "eks-oidc"  # Naming the role as "eks-oidc"
}

# Defining a custom IAM policy for the OIDC role with permissions to access S3 resources
resource "aws_iam_policy" "eks-oidc-policy" {
  name = "test-policy"  # Giving the policy a name

  # Defining policy document with permissions to list S3 buckets and get bucket locations
  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

# Attaching the custom OIDC policy to the previously created OIDC IAM role
resource "aws_iam_role_policy_attachment" "eks-oidc-policy-attach" {
  role       = aws_iam_role.eks_oidc.name  # Attaching the policy to the eks_oidc role
  policy_arn = aws_iam_policy.eks-oidc-policy.arn  # Attaching the policy ARN to the role
}
