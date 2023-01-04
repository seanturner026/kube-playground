provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      GithubRepo = "github.com/seanturner026/kube-playground"
      ManagedBy  = "terraform"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
