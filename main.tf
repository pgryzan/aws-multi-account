////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Author:         Patrick L. Gryzan
//  Repo:           aws-multi-account
//  File:           main.tf
//  Date:           August 2021
//  Description:    main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version    = ">= 1.0.5"
}

provider "aws" {
    region              = var.aws.region
    assume_role {
        role_arn        = "arn:aws:iam::${var.aws.account_id}:role/pgryzan"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  VPC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "vpc" {
    source              = "terraform-aws-modules/vpc/aws"

    name                = "${var.project.name} ${var.aws.environment}"
    cidr                = var.vpc.cidr[0]
    azs                 = var.vpc.zones
    private_subnets     = var.vpc.private_subnets
    public_subnets      = var.vpc.public_subnets
    enable_nat_gateway  = false
    enable_vpn_gateway  = false

    tags                = {
        Terraform       = "true"
        Environment     = var.aws.environment
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  S3 Bucket
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "aws_s3_bucket" "user_data" {
    bucket              = "${var.project.name}-${var.aws.environment}"
    acl                 = "private"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  IAM
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "aws_iam_policy" "s3_full" {
    name                = "s3_full_access"
    path                = "/"
    description         = "S3 Full access policy"
    policy              = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.user_data.arn}",
        "${aws_s3_bucket.user_data.arn}/*"
      ]
        
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_readonly" {
    name                = "s3_readonly_access"
    path                = "/"
    description         = "S3 Readonly access policy"
    policy              = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.user_data.arn}",
        "${aws_s3_bucket.user_data.arn}/*"
      ]
        
    }
  ]
}
EOF
}

# Allow IAM users from the main account to access this role
resource "aws_iam_role" "developers" {
    name                = "developers"
    assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

# Dev permissions
resource "aws_iam_role_policy_attachment" "developer_dev_s3_full" {
    count               = terraform.workspace == "dev" ? 1 : 0
    role                = aws_iam_role.developers.name
    policy_arn          = aws_iam_policy.s3_full.arn
}

# Test permissions
resource "aws_iam_role_policy_attachment" "test_dev_s3_full" {
    count               = terraform.workspace == "test" ? 1 : 0
    role                = aws_iam_role.developers.name
    policy_arn          = aws_iam_policy.s3_full.arn
}

# UAT permissions
resource "aws_iam_role_policy_attachment" "uat_dev_s3_readonly" {
    count               = terraform.workspace == "uat" ? 1 : 0
    role                = aws_iam_role.developers.name
    policy_arn          = aws_iam_policy.s3_readonly.arn
}

# Prod permissions
# No special permissions