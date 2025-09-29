#!/usr/bin/env bash
#   export AWS_REGION=ap-south-1  
#   export vpc_cidr="10.0.1.0/24" 
#   export vpc_name="ShaneVPC2"    
#   export ec2amiid="ami-02d26659fd82cf299"   

set -euo pipefail
IFS=$'\n\t'


trap 'ret=$?; echo "ERROR: Script failed at line $LINENO with exit code $ret"; exit $ret' ERR

# Required env vars
: "${ec2amiid:?ERROR: please export ec2amiid (example: export ec2amiid=ami-0123456789abcdef0)}"

echo "Starting creation for VPC '${vpc_name}' with CIDR ${vpc_cidr}"
echo "Using AMI: $ec2amiid"
echo "AWS region: ${AWS_REGION:-(unset)}"
echo

# 1) Create VPC
echo "Creating VPC..."
vpc_create_out=$(aws ec2 create-vpc --cidr-block "$vpc_cidr" --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$vpc_name}]" --region ap-south-1)
vpcid=$(echo "$vpc_create_out" | awk -F'"' '/VpcId/{print $4; exit}')
if [[ -z "$vpcid" ]]; then
  echo "Failed to create VPC or fetch VpcId"
  exit 1
fi
echo "Created VPC: $vpcid"

# 2) Create Subnets (public & private as per your plan)
echo "Creating subnets..."
# PublicSubnetA2 10.0.1.0/26 ap-south-1a
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.0/26 --availability-zone ap-south-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnetA2}]' >/dev/null
# PublicSubnetB2 10.0.1.160/27 ap-south-1b
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.160/27 --availability-zone ap-south-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnetB2}]' >/dev/null
# PublicSubnetC2 10.0.1.224/27 ap-south-1c
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.224/27 --availability-zone ap-south-1c --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnetC2}]' >/dev/null

# Private subnets
# PrivateSubnetB2 -10.0.1.64/26 -ap-south-1b
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.64/26 --availability-zone ap-south-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnetB2}]' >/dev/null
# PrivateSubnetA2 -10.0.1.128/27 -ap-south-1a
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.128/27 --availability-zone ap-south-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnetA2}]'  >/dev/null
# PrivateSubnetC2 -10.0.1.192/27 -ap-south-1c
aws ec2 create-subnet --vpc-id "$vpcid" --cidr-block 10.0.1.192/27 --availability-zone ap-south-1c --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnetC2}]'  >/dev/null

# Fetch subnet ids (first match of each name)
pubsubaid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PublicSubnetA2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)
pubsubbid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PublicSubnetB2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)
pubsubcid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PublicSubnetC2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)

prisubaid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetA2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)
prisubbid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetB2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)
prisubcid=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=PrivateSubnetC2" "Name=vpc-id,Values=$vpcid" --query "Subnets[0].SubnetId" --output text)

echo "Public subnets: $pubsubaid $pubsubbid $pubsubcid"
echo "Private subnets: $prisubaid $prisubbid $prisubcid"

# 3) Create and attach Internet Gateway
echo "Creating Internet Gateway..."
igwout=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ShaneVPC2igw}]')
igwid=$(echo "$igwout" | awk -F'"' '/InternetGatewayId/{print $4; exit}')
aws ec2 attach-internet-gateway --vpc-id "$vpcid" --internet-gateway-id "$igwid" 
echo "Created & attached IGW: $igwid"

# 4) Allocate Elastic IP for NAT
echo "Allocating Elastic IP for NAT gateway..."
eipallocid=$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=ShaneVPC2eip}]' --query 'AllocationId' --output text )
echo "Allocated EIP allocation-id: $eipallocid"

# 5) Create NAT Gateway in PublicSubnetA2 and wait until available
echo "Creating NAT Gateway in $pubsubaid..."
natout=$(aws ec2 create-nat-gateway --subnet-id "$pubsubaid" --allocation-id "$eipallocid" --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=ShaneVPC2natgw}]' )
natgwid=$(echo "$natout" | awk -F'"' '/NatGatewayId/{print $4; exit}')
echo "Created NAT gateway id: $natgwid"
echo "Waiting for NAT gateway to become available (this can take ~1-2 minutes)..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$natgwid"
echo "NAT gateway is available."

# 6) Create Public Route Table, add route to IGW, associate public subnets
echo "Creating public route table..."
pubrtout=$(aws ec2 create-route-table --vpc-id "$vpcid" --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=pubrtbvpc2}]' )
pubrtbvpc2id=$(echo "$pubrtout" | awk -F'"' '/RouteTableId/{print $4; exit}')
echo "Public route table: $pubrtbvpc2id"
aws ec2 create-route --route-table-id "$pubrtbvpc2id" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igwid" 
aws ec2 associate-route-table --subnet-id "$pubsubaid" --route-table-id "$pubrtbvpc2id" 
aws ec2 associate-route-table --subnet-id "$pubsubbid" --route-table-id "$pubrtbvpc2id" 
aws ec2 associate-route-table --subnet-id "$pubsubcid" --route-table-id "$pubrtbvpc2id" 
echo "Associated public subnets to public route table."

# 7) Create Private Route Table, add route to NAT, associate private subnets
echo "Creating private route table..."
privrtout=$(aws ec2 create-route-table --vpc-id "$vpcid" --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=prirtbvpc2}]' )
prirtbvpc2id=$(echo "$privrtout" | awk -F'"' '/RouteTableId/{print $4; exit}')
echo "Private route table: $prirtbvpc2id"
aws ec2 create-route --route-table-id "$prirtbvpc2id" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$natgwid" 
aws ec2 associate-route-table --subnet-id "$prisubaid" --route-table-id "$prirtbvpc2id"
aws ec2 associate-route-table --subnet-id "$prisubbid" --route-table-id "$prirtbvpc2id"
aws ec2 associate-route-table --subnet-id "$prisubcid" --route-table-id "$prirtbvpc2id" 
echo "Associated private subnets to private route table."

# 8) Create Security Groups (fail-fast if any command errors)
echo "Creating security groups..."
albwebsgcliid=$(aws ec2 create-security-group --group-name alb-web-sg-cli --vpc-id "$vpcid" --description "Security Group for Internet Facing ALB" --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=alb-web-sg-cli}]' --query 'GroupId' --output text)
chatwebsgcliid=$(aws ec2 create-security-group --group-name chat-web-sg-cli --vpc-id "$vpcid" --description "Security Group for Web EC2 / Web ASG" --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=chat-web-sg-cli}]'  --query 'GroupId' --output text)
albappsgcliid=$(aws ec2 create-security-group --group-name alb-app-sg-cli --vpc-id "$vpcid" --description "Security Group for Internal ALB" --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=alb-app-sg-cli}]'  --query 'GroupId' --output text)
chatappsgcliid=$(aws ec2 create-security-group --group-name chat-app-sg-cli --vpc-id "$vpcid" --description "Security Group for App EC2 / App ASG" --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=chat-app-sg-cli}]'  --query 'GroupId' --output text)
chatdbsgcliid=$(aws ec2 create-security-group --group-name chat-db-sg-cli --vpc-id "$vpcid" --description "Security Group for MySQL DB" \
--tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=db-sg-cli}]' --query 'GroupId' --output text)
chatbastsgcliid=$(aws ec2 create-security-group --group-name chat-bast-sg-cli --vpc-id "$vpcid" --description "SG for Bastion Host" \
--tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=chat-bast-sg-cli}]' --query 'GroupId' --output text)


echo "SG IDs:"
echo "  alb-web-sg-cli:  $albwebsgcliid"
echo "  chat-web-sg-cli: $chatwebsgcliid"
echo "  alb-app-sg-cli:  $albappsgcliid"
echo "  chat-app-sg-cli:  $chatappsgcliid"
echo "  chat-db-sg-cli:       $chatdbsgcliid"
echo "  chat-bast-sg-cli: $chatbastsgcliid"

# 9) Authorize SG rules (strict; will error and exit on any invalid parameter)
echo "Authorizing security group rules..."

# alb-web-sg-cli: Inbound 80 from 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$albwebsgcliid" --protocol tcp --port 80 --cidr 0.0.0.0/0 
# alb-web-sg-cli: Outbound 80 to chat-web-sg-cli
aws ec2 authorize-security-group-egress --group-id "$albwebsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":80,\"ToPort\":80,\"UserIdGroupPairs\":[{\"GroupId\":\"$chatwebsgcliid\"}]}]" 

# chat-web-sg-cli: Inbound 80 from alb-web-sg-cli
aws ec2 authorize-security-group-ingress --group-id "$chatwebsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":80,\"ToPort\":80,\"UserIdGroupPairs\":[{\"GroupId\":\"$albwebsgcliid\"}]}]" 

# chat-web-sg-cli: Outbound 80 to alb-app-sg-cli
aws ec2 authorize-security-group-egress --group-id "$chatwebsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":80,\"ToPort\":80,\"UserIdGroupPairs\":[{\"GroupId\":\"$albappsgcliid\"}]}]"  
aws ec2 authorize-security-group-ingress --group-id "$albappsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":80,\"ToPort\":80,\"UserIdGroupPairs\":[{\"GroupId\":\"$chatwebsgcliid\"}]}]"

# alb-app-sg-cli: Outbound 8001 to chat-app-sg-cli
aws ec2 authorize-security-group-egress --group-id "$albappsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":8001,\"ToPort\":8001,\"UserIdGroupPairs\":[{\"GroupId\":\"$chatappsgcliid\"}]}]" 

# chat-app-sg-cli: Inbound 8001 from alb-app-sg-cli
aws ec2 authorize-security-group-ingress --group-id "$chatappsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":8001,\"ToPort\":8001,\"UserIdGroupPairs\":[{\"GroupId\":\"$albappsgcliid\"}]}]"

# chat-app-sg-cli: Outbound 3306 to db-sg-cli
aws ec2 authorize-security-group-egress --group-id "$chatappsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":3306,\"ToPort\":3306,\"UserIdGroupPairs\":[{\"GroupId\":\"$chatdbsgcliid\"}]}]" 

# db-sg-cli: Inbound 3306 from chat-app-sg-cli
aws ec2 authorize-security-group-ingress --group-id "$chatdbsgcliid" --ip-permissions "[{\"IpProtocol\":\"tcp\",\"FromPort\":3306,\"ToPort\":3306,\"UserIdGroupPairs\":[{\"GroupId\":\"$chatappsgcliid\"}]}]" 

aws ec2 authorize-security-group-ingress \
  --group-id "$chatbastsgcliid" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0","Description":"SSH Access to BastionHost"}]}]'

# 2) Bastion egress: allow bastion to initiate SSH to the three tiers (tightest option)
aws ec2 authorize-security-group-egress \
  --group-id "$chatbastsgcliid" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"UserIdGroupPairs":[{"GroupId":"'"$chatwebsgcliid"'","Description":"to-web-sg"},{"GroupId":"'"$chatappsgcliid"'","Description":"to-app-sg"},{"GroupId":"'"$chatdbsgcliid"'","Description":"to-db-sg"}]}]'

# 3) Target SGs: allow SSH inbound FROM the bastion SG
aws ec2 authorize-security-group-ingress \
  --group-id "$chatwebsgcliid" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"UserIdGroupPairs":[{"GroupId":"'"$chatbastsgcliid"'"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id "$chatappsgcliid" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"UserIdGroupPairs":[{"GroupId":"'"$chatbastsgcliid"'"}]}]'

aws ec2 authorize-security-group-ingress \
  --group-id "$chatdbsgcliid" \
  --ip-permissions '[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"UserIdGroupPairs":[{"GroupId":"'"$chatbastsgcliid"'"}]}]'
# --- end SSH / Bastion rules ---


echo "Security group rules applied."


# 10) Create EC2 instances (examples) — ensure key pair 'chatapp' exists in your account and region
echo "Launching EC2 instances..."

# ChatDBA2 in private subnet (no public IP)
aws ec2 run-instances --image-id "$ec2amiid" --instance-type t3.micro --key-name "chatapp" --subnet-id "$prisubaid" --security-group-ids "$chatdbsgcliid" --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ChatDBA2}]' 

# ChatAppA2 in public subnet (example)
aws ec2 run-instances --image-id "$ec2amiid" --instance-type t3.micro --key-name "chatapp" --subnet-id "$pubsubaid" --security-group-ids "$chatappsgcliid" --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ChatAppA2}]' 

# ChatWebA2 in public subnet
aws ec2 run-instances --image-id "$ec2amiid" --instance-type t3.micro --key-name "chatapp" --subnet-id "$pubsubaid" --security-group-ids "$chatwebsgcliid" --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ChatWebA2}]' 

# BastionHostA2 in public subnet (associate public ip)
aws ec2 run-instances --image-id "$ec2amiid" --instance-type t3.micro --key-name "chatapp" --subnet-id "$pubsubaid" --security-group-ids "$chatbastsgcliid" --count 1 \
 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=BastionHostA2}]' --associate-public-ip-address 

echo "EC2 instances launched."

echo
echo "All resources created successfully."
echo "VPC: $vpcid"
echo "Subnets (public): $pubsubaid $pubsubbid $pubsubcid"
echo "Subnets (private): $prisubaid $prisubbid $prisubcid"
echo "IGW: $igwid   NATGW: $natgwid   EIP allocation: $eipallocid"
echo "RouteTables: public=$pubrtbvpc2id private=$prirtbvpc2id"
echo "Security Groups: alb-web=$albwebsgcliid chat-web=$chatwebsgcliid alb-app=$albappsgcliid chat-app=$chatappsgcliid chat-db=$chatdbsgcliid"
