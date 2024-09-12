# Data resource to retrieve the TLS certificate for the EKS cluster OIDC provider
data "tls_certificate" "eks-certificate" {
  # The URL for the OIDC identity issuer of the EKS cluster
  url = aws_eks_cluster.eks[0].identity[0].oidc[0].issuer
}

# IAM policy document for allowing EKS service accounts to assume roles via OIDC
data "aws_iam_policy_document" "eks_oidc_assume_role_policy" {
  # Define a statement that allows assuming roles with web identity (OIDC)
  statement {
    # The action allows assuming roles with web identity (OIDC)
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    # Define the condition that specifies which service accounts are allowed
    condition {
      test     = "StringEquals"
      # Use the issuer URL of the OIDC provider, removing the 'https://' part for the condition variable
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:sub"
      # Allow access only to the service account 'aws-test' in the 'default' Kubernetes namespace
      values   = ["system:serviceaccount:default:aws-test"]
    }

    # Define the principals, in this case, the OIDC provider itself
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks-oidc.arn]
      type        = "Federated"
    }
  }
}