resource "aws_security_group" "sg" {
  name        = "${var.name}-${var.env}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    description = "APP"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.allow_app_cidr

  }
  ingress {
    description = "SSH"
    from_port        =  22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name}-${var.env}-sg" }
}

resource "aws_launch_template" "template" {
  name_prefix   = "${var.name}-${var.env}-lt"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    name = var.name
    env = var.env } ))
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
}

resource "aws_autoscaling_group" "asg" {
  name   = "${var.name}-${var.env}-asg"
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns = [ aws_lb_target_group.tg.arn ]
  dynamic "tag" {
    for_each = local.asg_tags
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }


  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  }


resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-${var.env}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = { Name = "${var.name}-${var.env}-tg" }
  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 5
    timeout = 4
    path = "/health"
  }
}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = [local.dns_name]
    }
  }
  tags = { Name = "${var.name}-${var.env}-rule" }
}

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = local.dns_name
  type    = "CNAME"
  ttl     = 300
  records = [var.lb_dns_name]
}


