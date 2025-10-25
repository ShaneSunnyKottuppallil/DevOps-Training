resource "aws_ami_from_instance" "webami"{
    name="webami"
    source_instance_id=var.chatwebid
}

resource "aws_launch_template" "weblt"{
    name="weblt"
    instance_type=var.instancetype
    key_name=var.keyname
    image_id=aws_ami_from_instance.webami.id
    vpc_security_group_ids=[var.sgs["web"]]
    tag_specifications{
        resource_type="instance"
        tags={
            Name="chatweb3"
        }
    }
}

resource "aws_autoscaling_group" "webasg"{
    name="webasg"
    max_size=var.maxsize
    min_size=var.minsize
    desired_capacity=var.desiredcapacity
    launch_template{
        id=aws_launch_template.weblt.id
    }
    vpc_zone_identifier=[for k in ["aid","bid","cid"]:var.pubsub[k]]
}