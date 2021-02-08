variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_az" {
  description = "AWS availability zone to launch servers."
  default     = "us-east-1a"
}

variable "vpc_name" {
  description = "Name of the existing VPC which will be used"
  default     = "Default"
}

variable "instance_type" {
  description = "Type of instance used (API name)"
  default     = "t3a.xlarge"
}


variable "root_storage" {
  description = "Quantity of storage for root disk"
  default     = 20
}

variable "tags" {
  type = object({
    owner        = string
    project_name = string
    officehours  = string
  })
  default = {
    owner        = "myAWSname"
    project_name = "NginxOrigin"
    officehours  = "ParisOfficehours"
  }
}

variable "instance_names" {
  description = "Name and number of instances to create"
  default     = ["Origin_server"]
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = ""
}