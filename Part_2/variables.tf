variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use for authentication"
  default     = "default"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH Key pair name for accessing EC2 instance"
  default     = "my-key-pair"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  default     = "assignment135"
}
