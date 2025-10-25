provider "aws" {
  region = var.region
}



module "vpc" {
  source = "./modules/vpc_module"
  aza    = var.aza
  azb    = var.azb
  azc    = var.azc
}

module "sg" {
  source = "./modules/security_group_module"
  vpcid=module.vpc.vpcid
}

module "bast"{
    source="./modules/basthost_module"
    pubsub=module.vpc.pubsub
    sgs=module.sg.sgs
    amiid=var.amiid
    path_to_prikey=var.path_to_prikey
}

module "db"{
    source="./modules/database_module"
    prisub=module.vpc.prisub
    sgs=module.sg.sgs
    amiid=var.amiid
    chatbastpubip=module.bast.chatbastpubip
    path_to_prikey=var.path_to_prikey
}

module "app" {
  source="./modules/app_module"
  prisub=module.vpc.prisub
  sgs=module.sg.sgs
  amiid=var.amiid
  chatbastpubip=module.bast.chatbastpubip
  path_to_prikey=var.path_to_prikey
  instancetype=var.instancetype
  keyname=var.keyname
}

module "web"{
  source="./modules/web_module"
  pubsub=module.vpc.pubsub
  sgs=module.sg.sgs
  amiid=var.amiid
  chatbastpubip=module.bast.chatbastpubip
  path_to_prikey=var.path_to_prikey
  instancetype=var.instancetype
  keyname=var.keyname
}

module "intalb" {
  source="./modules/app_alb_module"
  vpcid=module.vpc.vpcid
  chatappid=module.app.chatappid
  sgs=module.sg.sgs
  prisub=module.vpc.prisub
}

module "pubalb" {
  source="./modules/web_alb_module"
  vpcid=module.vpc.vpcid
  chatwebid=module.web.chatwebid
  sgs=module.sg.sgs
  pubsub=module.vpc.pubsub
}

module "appasg" {
  source="./modules/app_asg_module"
  chatappid=module.app.chatappid
  instancetype=var.instancetype
  keyname=var.keyname
  sgs=module.sg.sgs
  prisub=module.vpc.prisub
}

module "webasg" {
  source="./modules/web_asg_module"
  chatwebid=module.web.chatwebid
  instancetype=var.instancetype
  keyname=var.keyname
  sgs=module.sg.sgs
  pubsub=module.vpc.pubsub
}

