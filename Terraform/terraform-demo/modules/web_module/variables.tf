variable "amiid"{
    description="AMI ID for chatweb"
    type=string
}

variable "instancetype"{
    description="Instance Type for Web Tier"
    type=string
    default="t2.micro"
}

variable "pubsub"{
    description="Public Subnet A Id"
    type=map(string)
}

variable "sgs"{
    description="Security Groups"
    type=map(string)
}

variable "keyname"{
    description="Keypair Name for EC2 instance"
    type=string
    default="chatapp"
}

variable "chatbastpubip"{
    description="Bastion Host Public Ip"
    type=string
}

variable "path_to_prikey"{
    description="path to private key based on region"
    type=string
}