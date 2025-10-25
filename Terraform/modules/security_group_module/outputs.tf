output "sgs" {
    description="All Security Group ids"
    value={
        app=aws_security_group.chatappsg.id
        web=aws_security_group.chatwebsg.id
        db=aws_security_group.chatdbsg.id
        bast=aws_security_group.chatbastsg.id
        albapp=aws_security_group.albappsg.id
        albweb=aws_security_group.albwebsg.id
    }
}

