output "vpcid"{
    description="VPC id"
    value=aws_vpc.ShaneVPC3.id
}


output "pubsub" {
    description="public subnets"
    value={
        aid=aws_subnet.pubsuba3.id
        bid=aws_subnet.pubsubb3.id
        cid=aws_subnet.pubsubc3.id
    }
}

output "prisub" {
    description="private subnets"
    value={
        aid=aws_subnet.prisuba3.id
        bid=aws_subnet.prisubb3.id
        cid=aws_subnet.prisubc3.id
    }
}


