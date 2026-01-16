variable "region" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "availability_zone" {
  type    = string
  default = "us-east-1a" # Default value if not specified
}