variable "region" {
  default = "us-east-1"
}

variable "public_cidr" {
  default = "10.0.1.0/24"
}

variable "private_cidr" {
  default = "10.0.2.0/24"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "my_ip" {
  description = "118.68.23.252"
}
