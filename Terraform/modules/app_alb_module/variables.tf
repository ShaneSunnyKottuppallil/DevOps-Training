variable "vpcid"{
 description="VPC Id"
 type=string   
}

variable "intalbport"{
 description="Internal ALB Port"
 type=number
 default=8001   
}

variable "intalbpro"{
 description="Listener Protocol "
 type=string
 default="HTTP"
}

variable "chatappid"{
 description="Chat App Instance ID"
 type=string   
}

variable "prisub"{
    description="Private Subnet IDs"
    type=map(string)
}

variable "sgs" {
    description="Security Group Map"
    type=map(string)
}

