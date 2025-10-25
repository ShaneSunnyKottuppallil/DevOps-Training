variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
  //default="ap-south-1"
}

variable "amiid" {
  type    = string
  default = "ami-0bbdd8c17ed981ef9" //ami for ubuntu 20.04 on us-east-1
  //default="ami-07f07a6e1060cd2a8"  //ami for ubuntu 20.04 on ap-south-1
}

variable "aza" {
  description = "availability_zone A"
  type        = string
  default     = "us-east-1a"
  //default="ap-south-1a"
}

variable "azb" {
  description = "availability_zone B"
  type        = string
  default     = "us-east-1b"
  //default="ap-south-1a"
}

variable "azc" {
  description = "availability_zone C"
  type        = string
  default     = "us-east-1c"
  //default="ap-south-1a"
}

variable "path_to_prikey"{
    description="path to private key based on region"
    type=string
    default="/home/ssk/Documents/chatapp.pem" //for us-east-1
    //default="/home/ssk/Downloads/chatapp.pem" //for ap-south-1
}

variable "instancetype"{
  description="Instance Type"
  type=string
  default="t2.micro"
}

variable "keyname"{
  description="Key name"
  type=string
  default="chatapp"
}