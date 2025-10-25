//Target Group for Load Balancer  (Instance)
resource "aws_lb_target_group" "pubalbtg"{
    name="internet-facing-alb-tg"
    port=var.pubalbport
    protocol=var.pubalbpro
    vpc_id=var.vpcid
}


//Attaching Instances to tg
resource "aws_lb_target_group_attachment" "pubalbtgatt"{
    target_group_arn=aws_lb_target_group.pubalbtg.arn
    target_id=var.chatwebid
    port=var.pubalbport
}


//Creating LB (Application Load Balancer)
resource "aws_lb" "pubalb"{
    name="internet-facing-alb"
    internal=false
    load_balancer_type="application"
    security_groups=[var.sgs["albweb"]]
    subnets=[for k in ["aid","bid","cid"] : var.pubsub[k]]
}

//Creating a listener rule for ALB. Listening and Forwarding Routes to Target Group
resource "aws_lb_listener" "pubalblist"{
    load_balancer_arn=aws_lb.pubalb.arn
    port=var.pubalbport
    protocol=var.pubalbpro

    default_action{
        type="forward"
        target_group_arn=aws_lb_target_group.pubalbtg.arn
    }
}
