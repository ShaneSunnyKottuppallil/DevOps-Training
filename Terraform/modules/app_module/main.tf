# trigger to replace chat app instance when bastion pub IP changes
resource "null_resource" "bastion_trigger" {
  triggers = {
    chatbastpubip = var.chatbastpubip
  }
}

resource "aws_instance" "chatapp3" {
  ami                    = var.amiid
  instance_type          = var.instancetype
  subnet_id              = var.prisub["aid"]          # ensure this key exists
  vpc_security_group_ids = [var.sgs["app"]]           # ensure this is an SG ID
  key_name               = var.keyname
  tags = {
    Name = "chatapp3"
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.bastion_trigger
    ]
  }
/*
  # connect to private IP via bastion
  connection {
    type                = "ssh"
    host                = self.private_ip
    user                = "ubuntu"
    private_key         = file(var.path_to_prikey)
    timeout             = "5m"                 # increase to be safe
    bastion_host        = var.chatbastpubip
    bastion_user        = "ubuntu"
    bastion_private_key = file(var.path_to_prikey)
  }

  provisioner "file" {
  source      = "${path.module}/scripts/bootstrap.sh"
  destination = "/home/ubuntu/bootstrap.sh"
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /home/ubuntu/bootstrap.sh",
    "sudo /home/ubuntu/bootstrap.sh"
  ]
}
*/
}
