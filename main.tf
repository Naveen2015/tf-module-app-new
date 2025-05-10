resource "aws_security_group" "sg" {
  name        = "${var.name}-${var.env}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    description = "APP"
    from_port        = 8080
    to_port          = 8080
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

  tags = "${var.name}-${var.env}-sg"
}

resource "aws_launch_template" "foobar" {
  name_prefix   = "${var.name}-${var.env}"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
}

# resource "aws_autoscaling_group" "bar" {
#   availability_zones = ["us-east-1a"]
#   desired_capacity   = 1
#   max_size           = 1
#   min_size           = 1
#
#   launch_template {
#     id      = aws_launch_template.foobar.id
#     version = "$Latest"
#   }
# }