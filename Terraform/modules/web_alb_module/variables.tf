variable "vpcid"{
 description="VPC Id"
 type=string   
}

variable "pubalbport"{
 description="Internet Facing ALB Port"
 type=number
 default=80   
}

variable "pubalbpro"{
 description="Listener Protocol "
 type=string
 default="HTTP"
}

variable "chatwebid"{
 description="Chat Web Instance ID"
 type=string   
}

variable "pubsub"{
    description="Private Subnet IDs"
    type=map(string)
}

variable "sgs" {
    description="Security Group Map"
    type=map(string)
}

