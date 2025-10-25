variable "chatappid"{
    description="Instance Id for App Instance"
    type=string
}

variable "instancetype"{
    description="Instance Type"
    type=string
}

variable "keyname" {
    description="Keyname for Chat App Instance"
    type=string
}

variable "sgs"{
    description="Security Groups"
    type=map(string)
}

variable "maxsize"{
    description="Maximum no of Instances"
    type=number
    default=3
}

variable "minsize"{
    description="Minimum no. of Instances"
    type=number
    default=1
}

variable "desiredcapacity"{
    description="Desired Number of Instances"
    type=number
    default=2
}

variable "prisub"{
    description="Private Subnet IDs"
    type=map(string)
}


