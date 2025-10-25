# trigger to replace chat app instance when bastion pub IP changes
resource "null_resource" "bastion_trigger" {
  triggers = {
    chatbastpubip = var.chatbastpubip
  }
}

resource "aws_instance" "chatweb3"{
    instance_type=var.instancetype
    subnet_id=var.pubsub["aid"]
    ami=var.amiid
    key_name=var.keyname
    vpc_security_group_ids=[var.sgs["web"]]
    tags={
        Name="chatweb3"
    }
    associate_public_ip_address = true
    lifecycle{
        replace_triggered_by=[
            null_resource.bastion_trigger
        ]
    }
}

