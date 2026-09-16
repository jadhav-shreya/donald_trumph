provider "aws" {
    region = "ap-south-1"
}

resource "aws_iam_role" "cluster2" {
  name = "eks-cluster2-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster2.name
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
  filter {
    name =  "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_eks_cluster" "cluster" {
    name = "cluster" 

    access_config {
      authentication_mode = "API"
    }

    role_arn = aws_iam_role.cluster2.arn

    vpc_config {
      subnet_ids = data.aws_subnets.default.ids
    }

    depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

}

resource "aws_iam_role" "node2" {
  name = "eks-node2-example"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "node2-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.node2.name
}

resource "aws_iam_role_policy_attachment" "node2-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.node2.name
}

resource "aws_iam_role_policy_attachment" "node2-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.node2.name
}

# resource "aws_iam_role_policy_attachment" "node2-AmazonElasticContainerRegistryPublicReadOnly " {
#     policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly "
#     role = aws_iam_role.node2.name
# }

resource "aws_eks_node_group" "node2" {
    cluster_name = aws_eks_cluster.cluster.name
    node_group_name = "node2"
    node_role_arn = aws_iam_role.node2.arn
    subnet_ids = data.aws_subnets.default.ids
    instance_types = ["c7i-flex.large"]

    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
  }

    update_config {
        max_unavailable = 1
  }

    depends_on = [
        aws_iam_role_policy_attachment.node2-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.node2-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.node2-AmazonEC2ContainerRegistryReadOnly,
        # aws-aws_iam_role_policy_attachment.node2-AmazonElasticContainerRegistryPublicReadOnly ,
  ]
}