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

data "aws_ami" "red_hat" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["309956199498"] # Red Hat Cloud Access
}

resource "aws_instance" "red_hat" {
  ami                     = data.aws_ami.red_hat.id
  instance_type           = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.proxy_security_group.id]
  subnet_id               = aws_subnet.proxy_subnet.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y nginx nginx-mod-stream firewalld policycoreutils-python-utils
              sudo systemctl start firewalld
              sudo firewall-cmd --permanent --add-port={443/tcp,9092/tcp}
              sudo firewall-cmd --reload
              sudo semanage port -a -t http_port_t -p tcp 9092
              sudo setsebool -P httpd_can_network_connect 1
              echo 'user nginx;
              worker_processes auto;
              pid /run/nginx.pid;
              load_module "/usr/lib64/nginx/modules/ngx_stream_module.so";
              include /etc/nginx/modules-enabled/*.conf;

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
