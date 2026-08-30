// iam role of the ec2
resource "aws_iam_role" "ec2_role_cloud_incient_project" {
  name = "ec2-iam-cloud-incident-project"
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

// used by ec2 ti use the role
resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2-instance-profile-cloud-incident-project"
  role = aws_iam_role.ec2_role_cloud_incient_project.name
}

//role by aws
// cloudwatch 
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role_cloud_incient_project.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

// connect to ec2
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role_cloud_incient_project.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// pulls images from ECR
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role_cloud_incient_project.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

// Custom inline policy 
// read tag on RDS database used by monitoring exporters)
resource "aws_iam_role_policy" "listtags" {
  name = "LISTTAGS"
  role = aws_iam_role.ec2_role_cloud_incient_project.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRDSListTags"
        Effect   = "Allow"
        Action   = "rds:ListTagsForResource"
        Resource = "arn:aws:rds:eu-west-3:351291606284:db:*"
      }
    ]
  })
}

// lets the YACE discover AWS resources by tag, for Prometheus scraping
resource "aws_iam_role_policy" "rds_metric_disc" {
  name = "RDS-Metric-disc"
  role = aws_iam_role.ec2_role_cloud_incient_project.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowYaceResourceDiscovery"
        Effect = "Allow"
        Action = [
          "tag:GetResources",
          "iam:ListAccountAliases"
        ]
        Resource = "*"
      }
    ]
  })
}

 
//allows the instance to list/describe EC2 instances, might remove it if not needed later 
resource "aws_iam_role_policy" "describe_ec2_instance" {
  name = "describe-ec2-instance"
  role = aws_iam_role.ec2_role_cloud_incient_project.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowEC2DescribeInstances"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      }
    ]
  })
}

// Custom inline policy: allows describing RDS instances (used by Grafana/Prometheus to pull RDS metadata)
resource "aws_iam_role_policy" "describe_rds_ec2" {
  name = "describe-RDS-ec2"
  role = aws_iam_role.ec2_role_cloud_incient_project.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRDSDescribe"
        Effect   = "Allow"
        Action   = "rds:DescribeDBInstances"
        Resource = "*"
      }
    ]
  })
}

// Custom inline policy: allows pulling CloudWatch metrics (EC2 + RDS) — this is what feeds Grafana dashboards via CloudWatch data
resource "aws_iam_role_policy" "cloudwatch_ec2_cloudincident" {
  name = "cloudwatch-ec2-cloudIncident"
  role = aws_iam_role.ec2_role_cloud_incient_project.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchMetricsAccess"
        Effect = "Allow"
        Action = [
          "tag:GetResources",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      }
    ]
  })
}
