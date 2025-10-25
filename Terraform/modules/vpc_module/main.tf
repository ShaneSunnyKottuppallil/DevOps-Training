
//VPC Creation
resource "aws_vpc" "ShaneVPC3" {
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "ShaneVPC3"
  }
  lifecycle {
    create_before_destroy = true
  }
}


locals{
  azs={
    aza="us-east-1a"
    azb="us-east-1b"
    azc="us-east-1c"
  }
}


//Subnets Creation
resource "aws_subnet" "prisuba3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.128/27"
  availability_zone = var.aza
  tags = {
    Name = "prisuba3"
  }
}

resource "aws_subnet" "prisubb3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.64/26"
  availability_zone = var.azb
  tags = {
    Name = "prisubb3"
  }
}


resource "aws_subnet" "prisubc3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.192/27"
  availability_zone = var.azc
  tags = {
    Name = "prisubc3"
  }
}

resource "aws_subnet" "pubsuba3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = var.aza
  tags = {
    Name = "pubsuba3"
  }
}


resource "aws_subnet" "pubsubb3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.160/27"
  availability_zone = var.azb
  tags = {
    Name = "pubsubb3"
  }
}

resource "aws_subnet" "pubsubc3" {
  vpc_id            = aws_vpc.ShaneVPC3.id
  cidr_block        = "10.0.2.224/27"
  availability_zone = var.azc
  tags = {
    Name = "pubsubc3"
  }
}



//Internet Gateway Creation
resource "aws_internet_gateway" "igw3" {
  vpc_id = aws_vpc.ShaneVPC3.id
  tags = {
    Name = "igw3"
  }
}




//Elastic IP creation for NatGateway
resource "aws_eip" "nateip3" {
  domain = "vpc"
  tags = {
    Name = "nateip3"
  }
}

//NatGateway Creation
resource "aws_nat_gateway" "natgw3" {
  allocation_id = aws_eip.nateip3.id
  subnet_id     = aws_subnet.pubsuba3.id
  tags = {
    Name = "natgw3"
  }
}



//Public Route Table and Route Creation
resource "aws_route_table" "pubrtb3" {
  vpc_id = aws_vpc.ShaneVPC3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw3.id
  }
  tags = {
    Name = "pubrtb3"
  }
}



//Creating Locals for subnet_id (Public and Private)
locals {
  pubsubid = {
    pubsuba3id = aws_subnet.pubsuba3.id
    pubsubb3id = aws_subnet.pubsubb3.id
    pubsubc3id = aws_subnet.pubsubc3.id
  }
  prisubid = {
    prisuba3id = aws_subnet.prisuba3.id
    prisubb3id = aws_subnet.prisubb3.id
    prisubc3id = aws_subnet.prisubc3.id
  }
}

//Route Table Associations
resource "aws_route_table_association" "pubrtbsubass" {
  for_each       = local.pubsubid
  subnet_id      = each.value
  route_table_id = aws_route_table.pubrtb3.id
}




//Private Route Table and Route Creation
resource "aws_route_table" "prirtb3" {
  vpc_id = aws_vpc.ShaneVPC3.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw3.id
  }

  tags = {
    Name = "prirtb3"
  }
}

//Private Route Table Associations
resource "aws_route_table_association" "prirtbsubass" {
  for_each       = local.prisubid
  subnet_id      = each.value
  route_table_id = aws_route_table.prirtb3.id
}














