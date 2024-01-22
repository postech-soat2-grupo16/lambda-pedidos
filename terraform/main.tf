provider "aws" {
  region = var.aws_region
}

#Configuração do Terraform State
terraform {
  backend "s3" {
    bucket = "terraform-state-soat"
    key    = "lambda-pedidos/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-soat-locking"
    encrypt        = true
  }
}

## .zip do código
data "archive_file" "code" {
  type        = "zip"
  source_dir  = "../src/code"
  output_path = "../src/code/code.zip"
}

#Security Group Lambda Pedidos
resource "aws_security_group" "security_group_lambda_pedidos" {
  name_prefix = "security_group_lambda_pedidos"
  description = "SG for Lambda Pedidos"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra   = "lambda"
    service = "pedidos"
    Name    = "security_group_lambda_pedidos"
  }
}

## Infra lambda fila pedidos
resource "aws_lambda_function" "lambda_pedidos" {
  function_name    = "lambda-pedidos"
  handler          = "lambda.main"
  runtime          = "python3.8"
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  role             = var.lambda_execution_role
  timeout          = 120
  description      = "Lamda para Fila de Pedidos"

  vpc_config {
    subnet_ids         = [var.subnet_a, var.subnet_b]
    security_group_ids = [aws_security_group.security_group_lambda_pedidos.id]
  }

  environment {
    variables = {
      "URL_BASE" = var.url_base
    }
  }

    tags = {
    infra   = "lambda"
    service = "pedidos"
  }
}

#Trigger SQS
resource "aws_lambda_event_source_mapping" "pedidos_sqs_trigger" {
  event_source_arn  = var.sqs_arn
  function_name     = aws_lambda_function.lambda_pedidos.arn
  enabled           = true
  batch_size        = 10
  starting_position = "LATEST"
}
