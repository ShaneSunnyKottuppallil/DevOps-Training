# Terraform Implementation

[![Terraform](https://img.shields.io/badge/Terraform-0.12%2B-blue)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Infrastructure-orange)](https://aws.amazon.com/)
[![Status](https://img.shields.io/badge/Status-Draft-yellowgreen)]()

---
---

## Table of contents

- [High-level architecture](#high-level-architecture)
- [Project wiring (how modules are used in root)](#project-wiring-how-modules-are-used-in-root)
- [Module-by-module detailed documentation](#module-by-module-detailed-documentation)
  - [module: vpc_module](#module-vpc_module)
  - [module: security_group_module](#module-security_group_module)
  - [module: basthost_module](#module-basthost_module)
  - [module: database_module](#module-database_module)
  - [module: app_module](#module-app_module)
  - [module: app_alb_module-internal-alb](#module-app_alb_module-internal-alb)
  - [module: web_alb_module-public-alb](#module-web_alb_module-public-alb)
  - [module: app_asg_module](#module-app_asg_module)
  - [module: web_asg_module](#module-web_asg_module)
- [Cross-cutting notes, gotchas, and risks](#cross-cutting-notes-gotchas-and-risks)
- [Suggested small improvements](#suggested-small-improvements)

---

## High-level architecture

**Networking** – A single VPC with 3 public and 3 private subnets across three AZs.  
**Internet** – Internet Gateway + NAT Gateway so private subnets can reach the internet.  
**Routing** – Route tables for public and private subnets.  
**Security** – Multiple Security Groups (web, app, db, ALBs, bastion) and ingress/egress rules connecting tiers.  
**Compute** – Bastion host (public) to access private instances.  
**Webtier** – A single “golden” web instance and an Auto Scaling Group (ASG) that uses an AMI baked from that instance.  
**Apptier** – A single “golden” app instance and an ASG baked similarly.  
**DBtier** – A private EC2 running MySQL, provisioned via remote-exec (through bastion).  
**Loadbalancing** – Public ALB in front of the web tier.  
**Internallb** – Internal ALB in front of the app tier.  
**Baking** – ASG modules use `aws_ami_from_instance` to create an AMI from the single instance created in the corresponding module, then the ASG launches instances from that AMI.  
**Root** – The root `main.tf` wires the modules together and passes outputs/IDs from one module to the next to establish dependencies and values.

---

## Project wiring (how modules are used in root)

- **VPC** – module "vpc" -> creates network and outputs `vpcid`, `pubsub`, `prisub`.  
- **SG** – module "sg" -> creates security groups, consumes `vpcid`, outputs `sgs`.  
- **Bastion** – module "bast" -> consumes public subnets + SGs; outputs `chatbastpubip`.  
- **DB** – module "db" -> consumes private subnets, SGs, AMI, bastion IP.  
- **App** – module "app" -> consumes private subnets, SGs, AMI, bastion IP; outputs `chatappid`.  
- **Web** – module "web" -> consumes public subnets, SGs, AMI, bastion IP; outputs `chatwebid`.  
- **Internalalb** – module "intalb" -> consumes VPC ID, app instance ID, SGs, private subnets.  
- **Publicalb** – module "pubalb" -> consumes VPC ID, web instance ID, SGs, public subnets.  
- **Appasg** – consumes `chatappid` to create AMI and ASG.  
- **Webasg** – consumes `chatwebid` to create AMI and ASG.

This enforces the order:  
**VPC → SG → Bastion → DB/App/Web → ALBs → ASGs**

---

# Module-by-module detailed documentation

---

### module: vpc_module

- **Purpose** – Create the VPC, NAT, public/private subnets across 3 AZs, and routing.  
- **Resources** – `aws_vpc`, `aws_subnet`, `aws_igw`, `aws_nat_gateway`, `aws_route_table`, `aws_route_table_association`.  
- **Inputs** – `aza`, `azb`, `azc`.  
- **Outputs** – `vpcid`, `pubsub`, `prisub`.  
- **Interactions** – Other modules consume these outputs.  
- **Notable** – CIDR is hardcoded, NAT only in AZ A, route tables correct, AZs parameterized.  
- **Recommendations** – Make CIDR configurable, multi-AZ NAT optional.

---

### module: security_group_module

- **Purpose** – Create security groups for web, app, db, ALBs, bastion.  
- **Resources** – `aws_security_group`, ingress rules, egress rules.  
- **Inputs** – `vpcid`.  
- **Outputs** – `sgs` map (app, web, db, bast, albapp, albweb).  
- **Interactions** – Passed to app, web, db, and ALB modules.  
- **Notable** – Several ports open to `0.0.0.0/0`, SG-to-SG rules well designed.  
- **Recommendations** – Restrict SSH, add more descriptive tags.

---

### module: basthost_module

- **Purpose** – Create a bastion host for SSH into private instances.  
- **Resources** – `aws_instance`, provisioners (copy key + chmod on remote).  
- **Inputs** – public subnets, SGs, AMI, key path, key name.  
- **Outputs** – `chatbastpubip`.  
- **Interactions** – Used by DB, app, web for provisioning.  
- **Notable** – Copies private key to bastion (security risk).  
- **Risks** – Storing private key, SSH open to world.  
- **Recommendations** – Use SSM Session Manager, restrict SSH, remove key copy.

---

### module: database_module

- **Purpose** – Launch DB EC2 and configure MySQL using remote-exec.  
- **Resources** – `aws_instance`, remote-exec for installation and configuration.  
- **Inputs** – AMI, instance type, private subnets, SGs, bastion IP, private key path.  
- **Outputs** – `chatdbpriip`.  
- **Interactions** – Receives app SG traffic, provisioning via bastion.  
- **Notable** – MySQL install via provisioner, bind-address 0.0.0.0.  
- **Risks** – Provisioners fragile, idempotency issues.  
- **Recommendations** – Use user-data, AMI baking, or RDS; parameterize DB credentials.

---

### module: app_module

- **Purpose** – Create single “golden” app instance used to bake AMI.  
- **Resources** – `aws_instance`, `null_resource` trigger.  
- **Inputs** – AMI, instance type, key name, key path, SGs, private subnets, bastion IP.  
- **Outputs** – `chatappid`.  
- **Interactions** – Used by app_asg_module.  
- **Notable** – Provisioners commented out; image may be incomplete.  
- **Risks** – AMI may capture partial state.  
- **Recommendations** – Use Packer, user-data, proper image lifecycle.

---

### module: app_alb_module (internal ALB)

- **Purpose** – Internal ALB for app tier.  
- **Resources** – `aws_lb`, `aws_lb_target_group`, listener, attachment.  
- **Inputs** – VPC ID, app instance ID, SGs, private subnets, port/protocol.  
- **Interactions** – ALB SG uses albapp; app SG allows port 8001.  
- **Notable** – Routes internal traffic only.

---

### module: web_alb_module (public ALB)

- **Purpose** – Internet-facing ALB for web tier.  
- **Resources** – `aws_lb`, target group, listener, attachment.  
- **Inputs** – VPC ID, web instance ID, SGs, public subnets, port/protocol.  
- **Interactions** – SG allows `0.0.0.0/0` on port 80.  
- **Notable** – Public ALB + public web instance (common demo pattern).

---

### module: app_asg_module

- **Purpose** – Bake AMI and create ASG for app tier.  
- **Resources** – `aws_ami_from_instance`, launch template, ASG.  
- **Inputs** – instance ID, instance type, key name, SGs, private subnets, scaling settings.  
- **Notable** – AMIs created on apply; may produce many AMIs.  
- **Risks** – AMI sprawl, dependency on instance existence.  
- **Recommendations** – Use Packer, add AMI lifecycle.

---

### module: web_asg_module

- **Purpose** – Same as app ASG but for web tier.  
- **Inputs** – instance ID, SGs, public subnets, instance settings.  
- **Notes** – Same risks and improvements as app ASG.

---

## Cross-cutting notes, gotchas, and risks

- **Provisioners** – Fragile, prefer user-data or baked images.  
- **Imagebaking** – Use of `aws_ami_from_instance` is demo-friendly but not CI-friendly.  
- **Security** – SSH open to world, private key copied to bastion.  
- **Hardcoded** – CIDR, AMI, AZs, key paths.  
- **NAT** – Single NAT only.  
- **Tagging** – Could be more consistent.  
- **Outputs** – Root outputs empty.  
- **Lifecycle** – AMI creation may break if instance replaced.

---

## Suggested small improvements

- **Addoutputs** – Bastion IP, ALB DNS, ASG names.  
- **Parameterize** – CIDR, NAT, AMI.  
- **Replace** – Provisioners with user-data or Packer.  
- **Removekey** – Don’t store private key on bastion.  
- **Tags** – Add environment, owner, cost tags.  
- **IAM** – Ensure required permissions.  
- **Keys** – Make key path optional.

---
