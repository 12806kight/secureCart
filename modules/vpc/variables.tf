variable "project" {
  type    = string
  default = "securecart"
}


variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnets" {
  type = map(object({
    cidr_block = string
    az         = string
    type       = string
  }))
  default = {
    private_a = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-1a"
      type       = "private"
    }
    private_b = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-1b"
      type       = "private"
    }
    public_a = {
      cidr_block = "10.0.3.0/24"
      az         = "us-east-1a"
      type       = "public"
    }
    public_b = {
      cidr_block = "10.0.4.0/24"
      az         = "us-east-1b"
      type       = "public"
    }
  }
}

variable "public_route_cidr_block" {
  description = "The CIDR block for the public route table"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_route_cidr_block" {
  description = "The CIDR block for the PRIVATE route table"
  type        = string
  default     = "0.0.0.0/0"
}


