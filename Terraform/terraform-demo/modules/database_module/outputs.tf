output "chatdbpriip"{
    description="Private IP address of chatdb3"
    value=aws_instance.chatdb3.private_ip
}
