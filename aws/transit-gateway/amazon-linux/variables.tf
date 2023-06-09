variable "subnet_id" {
  description = "The subnet ID of a subnet associated with your Transit Gateway attachment"
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

variable "confluent_cloud_endpoint" {
  description = "Your Confluent Cloud cluster endpoint. Remeber to exclude the ':9092' part from the Bootstrap server"
  type        = string
}
