provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}
#Network
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default subnet for us-east-1a"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "Default subnet for us-east-1b"
  }
}

# ELBSG
resource "aws_security_group" "ELBSG" {
  name        = "ELBSG"
  description = "ELBSG"
  vpc_id      = aws_default_vpc.default.id  
}

resource "aws_security_group_rule" "AllowAllIngressELB" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ELBSG.id
}

resource "aws_security_group_rule" "AllowAllEgressELB" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ELBSG.id
}
# Instances

resource "aws_instance" "FrontEnd1" {
  ami           = "ami-0ed9277fb7eb570c9"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.ELBSG.id]
  subnet_id = aws_default_subnet.default_az1.id
  associate_public_ip_address = true
  user_data = "${file("installnginx.sh")}"

  tags = {
    Name = "FrontEnd1"
  }
  depends_on = [
    aws_default_subnet.default_az1,
  ]
}

resource "aws_instance" "FrontEnd2" {
  ami           = "ami-0ed9277fb7eb570c9"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.ELBSG.id]
  subnet_id = aws_default_subnet.default_az2.id
  associate_public_ip_address = true
  user_data = "${file("installnginx.sh")}"

  tags = {
    Name = "FrontEnd2"
  }
    depends_on = [
    aws_default_subnet.default_az2,
  ]
}

# Target Group

resource "aws_lb_target_group" "FrontEndTG" {
  name     = "FrontEndTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "TGAttachmentFrontEnd1" {
  target_group_arn = aws_lb_target_group.FrontEndTG.arn
  target_id        = aws_instance.FrontEnd1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TGAttachmentFrontEnd2" {
  target_group_arn = aws_lb_target_group.FrontEndTG.arn
  target_id        = aws_instance.FrontEnd2.id
  port             = 80
}

resource "aws_lb" "FrontEndELB" {
  name               = "FrontEndELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ELBSG.id]
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.FrontEndELB.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.FrontEndTG.arn
  }
}