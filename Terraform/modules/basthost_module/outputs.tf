output "chatbastpubip"{
    description="Public IP address of chatbast3"
    value=aws_instance.chatbast3.public_ip
}
