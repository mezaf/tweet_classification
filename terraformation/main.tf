provider "aws" {
  region = "us-east-1"
}

locals {
  master_password         = var.create_random_password ? random_password.master_password[0].result : var.password
}

resource "aws_kms_key" "default_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "random_password" "master_password" {
  count = 1

  length  = 10
  special = false
}

resource "aws_rds_cluster" "main" {
  engine_mode             = "serverless"
  cluster_identifier      = "main-db"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["us-east-1a"]
  database_name           = "dollmvp"
  master_username         = var.username
  master_password         = local.master_password
  backup_retention_period = 1
  preferred_backup_window = "01:00-03:00"
  port                    = 3306
  skip_final_snapshot     = true
}

resource "aws_iam_role" "role_lambda_cleanRecords" {
  name = "recordHandler"
  assume_role_policy = templatefile("./templates/role_lambda_cleanRecords.json.tpl", {s3_bucket = data.aws_s3_bucket.main.bucket_domain_name})
}

resource "aws_lambda_layer_version" "fuzzy_wuzzy" {
  filename            = "../Lib/tweet_classification.zip"
  layer_name          = "fuzzy_wuzzy"
  compatible_runtimes = ["python3.7","python3.8"]
  description         = "Library to handle an automated classification of tweets"
}

resource "aws_lambda_function" "cleanRecords" {
  filename      = "../lambda_function.zip"
  function_name = "tweet_automated_classification"
  role          = aws_iam_role.role_lambda_cleanRecords.arn
  runtime       = "python3.8"
  environment {
    variables   = {
      host      = aws_rds_cluster.main.endpoint
      user      = var.username
      password  = var.password
    }
  }
}

terraform {
  backend "s3" {
    bucket = "doll-platform-artifacts"
    key = "core-platform/terraform.tfstate"
    region = "us-east-1"
  }
}