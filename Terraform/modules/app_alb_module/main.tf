//Target Group for Load Balancer  (Instance)
resource "aws_lb_target_group" "intalbtg"{
    name="internal-alb-tg"
    port=var.intalbport
    protocol=var.intalbpro
    vpc_id=var.vpcid
}


//Attaching Instances to tg
resource "aws_lb_target_group_attachment" "intalbtgatt"{
    target_group_arn=aws_lb_target_group.intalbtg.arn
    target_id=var.chatappid
    port=var.intalbport
}


//Creating LB (Application Load Balancer)
resource "aws_lb" "intalb"{
    name="internalalb"
    internal=true
    load_balancer_type="application"
    security_groups=[var.sgs["albapp"]]
    subnets=[for k in ["aid","bid","cid"] : var.prisub[k]]
}

//Creating a listener rule for ALB. Listening and Forwarding Routes to Target Group
resource "aws_lb_listener" "intalblist"{
    load_balancer_arn=aws_lb.intalb.arn
    port=var.intalbport
    protocol=var.intalbpro

    default_action{
        type="forward"
        target_group_arn=aws_lb_target_group.intalbtg.arn
    }
}
