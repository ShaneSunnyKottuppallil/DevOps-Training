resource "aws_instance" "chatdb3"{
    ami=var.amiid
    instance_type=var.instancetype
    subnet_id=var.prisub["aid"]
    vpc_security_group_ids=[var.sgs["db"]]
    key_name=var.keyname
    tags={
        Name="chatdb3"
    }

    connection {
        type="ssh"
        host=self.private_ip
        user="ubuntu"
        private_key=file(var.path_to_prikey)
        timeout="4m"
        bastion_host=var.chatbastpubip
        bastion_user="ubuntu"
        bastion_private_key=file(var.path_to_prikey)
    }

    provisioner "remote-exec" {
        inline = [
            "mkdir shane",
            "sudo apt update",
            "sudo apt install -y mysql-server",
            "sudo systemctl enable --now mysql",
            "sudo sed -i 's/^bind-address.*/bind-address=0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf",
            "sudo systemctl restart mysql",
            "sleep 5",
            "sudo systemctl status --no-pager mysql",
            "sudo mysql -e \"CREATE DATABASE IF NOT EXISTS fundoodb;\"",
            "sudo mysql -e \"CREATE USER IF NOT EXISTS 'fundoo'@'%' IDENTIFIED BY 'fundoo123';\"",
            "sudo mysql -e \"GRANT ALL PRIVILEGES ON fundoodb.* TO 'fundoo'@'%'; FLUSH PRIVILEGES;\""
        ]
    }

}

