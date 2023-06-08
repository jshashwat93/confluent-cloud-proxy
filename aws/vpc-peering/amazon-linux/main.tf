terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 2.32.0"
    }
  }
}

provider "aws" {
  region = var.customer_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_subnet" "proxy_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr
  tags = {
    Name = "proxy_subnet"
  }
}

resource "aws_route_table_association" "proxy_subnet_association" {
  subnet_id      = aws_subnet.proxy_subnet.id
  route_table_id = var.route_table_id
}

resource "aws_security_group" "proxy_security_group" {
  name        = "proxy_security_group"
  description = "Security Group associated with the subnet created for the proxy server"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow 9092 for all"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 22 for all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 443 for all"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al*-ami-*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "amazon_linux" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.proxy_security_group.id]
  subnet_id               = aws_subnet.proxy_subnet.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y install nginx nginx-mod-stream
              echo 'user nginx;
              worker_processes auto;
              pid /run/nginx.pid;
              load_module "/usr/lib64/nginx/modules/ngx_stream_module.so";

              events {}
              stream {
                map $ssl_preread_server_name $targetBackend {
                  default $ssl_preread_server_name;
                }

                server {
                  listen 443;
                  proxy_connect_timeout 5s;
                  proxy_timeout 7200s;
                  resolver 169.254.169.253;
                  proxy_pass $targetBackend:443;
                  ssl_preread on;
                }

                server {
                  listen 9092;
                  proxy_connect_timeout 5s;
                  proxy_timeout 7200s;
                  resolver 169.254.169.253;
                  proxy_pass $targetBackend:9092;
                  ssl_preread on;
                }
              }' | sudo tee /etc/nginx/nginx.conf
              sudo systemctl restart nginx
              EOF
  tags = {
    Name = "Proxy Server"
  }
}

