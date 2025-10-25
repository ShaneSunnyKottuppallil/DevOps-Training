
//AWS Security Groups Creation
resource "aws_security_group" "chatwebsg"{
	vpc_id=var.vpcid
	name="chatwebsg"
	description="This is Security Group for Chat Web Tier"
}

resource "aws_security_group" "chatappsg"{
	vpc_id=var.vpcid
	name="chatappsg"
	description="This is Security Group for Chat App Tier"
}

resource "aws_security_group" "chatdbsg"{
	vpc_id=var.vpcid
	name="chatdbsg"
	description="This is Security Group for DB Tier"
}

resource "aws_security_group" "albwebsg"{
	vpc_id=var.vpcid
	name="albwebsg"
	description="SG for ALB infront of Web Tier"
}

resource "aws_security_group" "albappsg" {
	vpc_id=var.vpcid
	name="albappsg"
	description="SG for ALB infront of App Tier"
}

resource "aws_security_group" "chatbastsg"{
	vpc_id=var.vpcid
	name="chatbastsg"
	description="SG for Bastion Host"
}

//Random Security Group for tainting
resource "aws_security_group" "random-sg"{
  vpc_id=var.vpcid
  name="random-sg"
  description="Random SG for checking tainting"
}




locals{
  sgs={
    chatdbsgid=aws_security_group.chatdbsg.id
    chatwebsgid=aws_security_group.chatwebsg.id
    chatappsgid=aws_security_group.chatappsg.id
  }
}




//chatwebsg,chatappsg,chatdbsg ingress
resource "aws_vpc_security_group_ingress_rule" "chatsgsin"{
  for_each=local.sgs
  security_group_id=each.value
  referenced_security_group_id=aws_security_group.chatbastsg.id
  from_port=22
  to_port=22
  ip_protocol="tcp"
}

//chatwebsg ingress
resource "aws_vpc_security_group_ingress_rule" "chatwebsgin"{
  security_group_id=aws_security_group.chatwebsg.id
  //referenced_security_group_id=aws_security_group.chatwebsg.id
  cidr_ipv4="0.0.0.0/0"
  from_port=80
  to_port=80
  ip_protocol="tcp"
}


//chatappsg ingress
resource "aws_vpc_security_group_ingress_rule" "chatappsgin"{
  security_group_id=aws_security_group.chatappsg.id
  referenced_security_group_id=aws_security_group.albappsg.id
  from_port=8001
  to_port=8001
  ip_protocol="tcp"
}


//chatdbsg ingress
resource "aws_vpc_security_group_ingress_rule" "chatdbsgin"{
  security_group_id=aws_security_group.chatdbsg.id
  referenced_security_group_id=aws_security_group.chatappsg.id
  from_port=3306
  to_port=3306
  ip_protocol="tcp"
}

//chatbast ingress
resource "aws_vpc_security_group_ingress_rule" "chatbastsgin"{
  security_group_id=aws_security_group.chatbastsg.id
  cidr_ipv4="0.0.0.0/0"
  from_port=22
  to_port=22
  ip_protocol="tcp"
}


//albappsg ingress
resource "aws_vpc_security_group_ingress_rule" "albappsgin" {
  security_group_id=aws_security_group.albappsg.id
  //referenced_security_group_id=aws_security_group.chatappsg.id
  cidr_ipv4="0.0.0.0/0"
  from_port=8001
  to_port=8001
  ip_protocol="tcp"
}


//albwebsg ingress
resource "aws_vpc_security_group_ingress_rule" "albwebsgin"{
  security_group_id=aws_security_group.albwebsg.id
  cidr_ipv4="0.0.0.0/0"
  from_port=80
  to_port=80
  ip_protocol="tcp"
}


locals{
  sgall={
    chatdbsgid=aws_security_group.chatdbsg.id
    chatwebsgid=aws_security_group.chatwebsg.id
    chatappsgid=aws_security_group.chatappsg.id
    albappsgid=aws_security_group.albappsg.id
    albwebsgid=aws_security_group.albwebsg.id
    chatbastsgid=aws_security_group.chatbastsg.id
  }
}


//egress for all traffic
resource "aws_vpc_security_group_egress_rule" "egress"{
  for_each=local.sgall
  security_group_id=each.value
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol="-1"
}

