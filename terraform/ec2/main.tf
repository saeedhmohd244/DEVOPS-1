variable "ami" {}
variable "type" {}
variable "amitemplate" {}
variable "amitype" {}

resource "aws_instance" "nginx1" {
    ami           = var.ami
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.asg1.id]
    subnet_id = aws_subnet.private[0].id
    tags = {
    Name = "nginx-${count.index + 1}"
        }
    key_name = "AWs_key.pem"
   }

resource "aws_instance" "nginx2" {
    ami           = var.ami
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.asg1.id]
    subnet_id = aws_subnet.private[1].id
    tags = {
    Name = "nginx-${count.index + 2}"
        }
    key_name = "AWs_key.pem"
   }

resource "aws_instance" "app1" {
    ami           = var.ami
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.asg2.id]
    subnet_id = aws_subnet.private[2].id
    tags = {
    Name = "app-${count.index + 1}"
        }
    key_name = "AWs_key.pem"
   }

resource "aws_instance" "app2" {
    ami           = var.ami
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.asg2.id]
    subnet_id = aws_subnet.private[3].id
    tags = {
    Name = "app-${count.index + 2}"
        }
    key_name = "AWs_key.pem"
   }

resource "aws_instance" "db" {
    ami           = var.ami
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.default.id]
    subnet_id = aws_subnet.private[4].id
    tags = {
    Name = "db-${count.index + 1}"
        }
    key_name = "AWs_key.pem"
   }

resource "aws_launch_template" "template1" {
    name = "template1"
    image_id = element(var.amitemplate[0])
    instance_type = var.amitype
    security_group_names = aws_security_group.asg1.id
    key_name = "AWs_key.pem"
    network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg1.id]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "asg1" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  
  launch_template {
    id      = aws_launch_template.template1.id
    version = "$Latest"   # This ensures you're using the latest version of the launch template
  }

  tag {
    key                 = "asg1"
    value               = "my-asg-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"      # Optional: Health check type for the instances
  health_check_grace_period = 300        # Optional: Time to wait before starting health checks after an instance is launched
}

resource "aws_autoscaling_group" "asg2" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private[2].id, aws_subnet.private[3].id]
  
  launch_template {
    id      = aws_launch_template.template1.id
    version = "$Latest"   # This ensures you're using the latest version of the launch template
  }

  tag {
    key                 = "asg2"
    value               = "my-asg-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"      # Optional: Health check type for the instances
  health_check_grace_period = 300        # Optional: Time to wait before starting health checks after an instance is launched
}

resource "aws_lb_target_group" "lbtg" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myvpc[0].id
  target_type = "instance"  

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb" "lb1" {
    name               = "my-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lbsg.id,aws_security_group.asg2.id,aws_security_group.asg1.id]
    subnets            = [aws_subnet.public[6].id, aws_subnet.public[0].id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }
}

# Attach Auto Scaling Groups to the Target Group via Listener
resource "aws_autoscaling_policy" "scale_out_asg1" {
  name                   = "scale-out-asg1"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg1.name
}

resource "aws_autoscaling_policy" "scale_in_asg1" {
  name                   = "scale-in-asg1"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg1.name
}

resource "aws_autoscaling_policy" "scale_out_asg2" {
  name                   = "scale-out-asg2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg2.name
}

resource "aws_autoscaling_policy" "scale_in_asg2" {
  name                   = "scale-in-asg2"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg2.name
}