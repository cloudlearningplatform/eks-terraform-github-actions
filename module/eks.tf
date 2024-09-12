# EKS Cluster
resource "aws_eks_cluster" "eks" {
  # Only create the cluster if the 'is-eks-cluster-enabled' variable is set to true
  count    = var.is-eks-cluster-enabled == true ? 1 : 0
  
  # Cluster name and Kubernetes version from variables
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-cluster-role[count.index].arn
  version  = var.cluster-version

  # VPC configuration for the EKS cluster, specifying private subnets and security group
  vpc_config {
    subnet_ids              = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]
    endpoint_private_access = var.endpoint-private-access  # Whether the API server is accessible via private endpoint
    endpoint_public_access  = var.endpoint-public-access   # Whether the API server is accessible via public endpoint
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
  }

  # Access configuration for the EKS cluster
  access_config {
    authentication_mode                         = "CONFIG_MAP"  # Authentication mode for API access
    bootstrap_cluster_creator_admin_permissions = true  # Grant admin permissions to the creator of the cluster
  }

  # Tags for the EKS cluster
  tags = {
    Name = var.cluster-name
    Env  = var.env  # Environment tag (e.g., dev, prod)
  }
}

# OIDC Provider for IAM roles associated with Kubernetes Service Accounts
resource "aws_iam_openid_connect_provider" "eks-oidc" {
  # Allow sts.amazonaws.com as the client for OIDC
  client_id_list  = ["sts.amazonaws.com"]
  
  # Thumbprint of the OIDC server's TLS certificate
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  
  # OIDC URL for the EKS cluster
  url             = data.tls_certificate.eks-certificate.url
}

# EKS Add-ons
resource "aws_eks_addon" "eks-addons" {
  # Loop through the list of add-ons passed via the variable and create each one
  for_each      = { for idx, addon in var.addons : idx => addon }
  
  # Associate the add-ons with the EKS cluster
  cluster_name  = aws_eks_cluster.eks[0].name
  
  # Add-on name and version (passed via variable)
  addon_name    = each.value.name
  addon_version = each.value.version

  # Ensure node groups are created before add-ons
  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

# On-Demand Node Group
resource "aws_eks_node_group" "ondemand-node" {
  # Associate the node group with the EKS cluster
  cluster_name    = aws_eks_cluster.eks[0].name
  
  # Node group name and role
  node_group_name = "${var.cluster-name}-on-demand-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroup-role[0].arn

  # Scaling configuration (desired, min, max sizes) for on-demand nodes
  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }

  # Subnets for the on-demand nodes (private subnets for security)
  subnet_ids = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]

  # Instance types for on-demand nodes (passed via variable)
  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"  # Capacity type set to On-Demand

  # Labels to distinguish this node group as on-demand
  labels = {
    type = "ondemand"
  }

  # Update configuration for rolling updates (max number of unavailable nodes during update)
  update_config {
    max_unavailable = 1
  }

  # Tags for the on-demand node group
  tags = {
    "Name" = "${var.cluster-name}-ondemand-nodes"
  }

  # Ensure the EKS cluster is created before the node group
  depends_on = [aws_eks_cluster.eks]
}

# Spot Instance Node Group
resource "aws_eks_node_group" "spot-node" {
  # Associate the node group with the EKS cluster
  cluster_name    = aws_eks_cluster.eks[0].name
  
  # Node group name and role for spot instances
  node_group_name = "${var.cluster-name}-spot-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroup-role[0].arn

  # Scaling configuration (desired, min, max sizes) for spot nodes
  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }

  # Subnets for the spot node group (private subnets)
  subnet_ids = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]

  # Instance types for spot instances (passed via variable)
  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"  # Capacity type set to Spot for cost savings

  # Update configuration for rolling updates
  update_config {
    max_unavailable = 1
  }

  # Disk size for the spot node group
  disk_size = 50

  # Tags for the spot node group
  tags = {
    "Name" = "${var.cluster-name}-spot-nodes"
  }

  # Labels to distinguish this node group as spot instances
  labels = {
    type      = "spot"
    lifecycle = "spot"
  }

  # Ensure the EKS cluster is created before the spot node group
  depends_on = [aws_eks_cluster.eks]
}