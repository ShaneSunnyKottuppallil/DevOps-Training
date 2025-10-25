variable "amiid"{
    description="AMI Id for ec2 Instance"
    type=string
}

variable "keyname"{
    description="Keypair Name for EC2 instance"
    type=string
    default="chatapp"
}

variable "instancetype" {
    description="Instance Type for DB instance"
    type=string
    default="t2.micro"
}

variable "sgs"{
    description="Security Group Map"
    type=map(string)
}

variable "prisub"{
    description="Subnet on which ec2 instance is created."
    type=map(string)
}

variable "chatbastpubip"{
    description="Bastion Host Public Ip"
    type=string
}

variable "path_to_prikey"{
    description="path to private key based on region"
    type=string
}