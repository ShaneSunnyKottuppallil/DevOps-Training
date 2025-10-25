variable "amiid"{
    description="AMI Id for ec2 Instance"
    type=string
}

variable "instancetype" {
    description="Instance Type for DB instance"
    type=string
    default="t2.micro"
}

variable "pubsub"{
    type=map(string)
}

variable "sgs" {
    type=map(string)
}

variable "keyname"{
    description="Keypair Name for EC2 instance"
    type=string
    default="chatapp"
}

variable "path_to_prikey"{
    description="path to private key based on region"
    type=string
}