variable "vpc_id" {
  description = "The ID of the VPC peered with Confluent."
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR to create a subnet in."
  type        = string
}

variable "aws_access_key" {
  description = "AWS API Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "customer_region" {
  description = "The region of the VPC."
  type        = string
}

variable "route_table_id" {
  description = "The route table ID which has route to Confluent peering."
  type        = string
}

variable "confluent_cloud_endpoint" {
  description = "Your Confluent Cloud cluster endpoint. Remeber to exclude the ':9092' part from the Bootstrap server"
  type        = string
}
