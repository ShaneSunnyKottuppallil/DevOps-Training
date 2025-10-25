resource "aws_ami_from_instance" "appami"{
    name="appami"
    source_instance_id=var.chatappid
}

resource "aws_launch_template" "applt"{
    name="applt"
    instance_type=var.instancetype
    key_name=var.keyname
    image_id=aws_ami_from_instance.appami.id
    vpc_security_group_ids=[var.sgs["app"]]
    tag_specifications{
        resource_type="instance"
        tags={
            Name="chatapp3"
        }
    }
}

resource "aws_autoscaling_group" "appasg"{
    name="appasg"
    max_size=var.maxsize
    min_size=var.minsize
    desired_capacity=var.desiredcapacity
    launch_template{
        id=aws_launch_template.applt.id
    }
    vpc_zone_identifier=[for k in ["aid","bid","cid"]:var.prisub[k]]
}