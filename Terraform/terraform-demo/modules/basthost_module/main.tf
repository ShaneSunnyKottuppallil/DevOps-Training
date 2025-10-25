resource "aws_instance" "chatbast3"{
    ami=var.amiid
    instance_type=var.instancetype
    subnet_id=var.pubsub["aid"]
    key_name=var.keyname
    vpc_security_group_ids=[var.sgs["bast"]]
    tags={
        Name="chatbast3"
    }
    associate_public_ip_address = true

    
    connection{
        type="ssh"
        host=self.public_ip
        user="ubuntu"
        private_key=file(var.path_to_prikey)
        timeout="4m"
    }
    
    provisioner "file"{
        source=var.path_to_prikey
        destination="/home/ubuntu/chatapp.pem"
    }

    provisioner "remote-exec" {
        
        inline = [
            "cd ~",
            "chmod 400 chatapp.pem"
        ]
    }
}

