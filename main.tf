provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA5TW7O3UYE6XF3ZHS"
  secret_key = "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"
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

#FrontEndSG
resource "aws_security_group" "FrontEndSG" {
  name        = "FrontEndSG"
  description = "FrontEndSG"
  vpc_id      = aws_default_vpc.default.id  
}

resource "aws_security_group_rule" "AllowAllIngressFrontEnd" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = [aws_security_group.ELBSG.cidr_blocks]
  security_group_id = aws_security_group.FrontEndSG.id
}

resource "aws_security_group_rule" "AllowAllEgressFrontEnd" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = [aws_security_group.ELBSG.cidr_blocks]
  security_group_id = aws_security_group.FrontEndSG.id
}

# ELB

resource "aws_lb" "FronEndELB" {
  name               = "FronEndELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ELBSG.id]
  subnets            = [aws_default_subnet.default_az1, aws_default_subnet.default_az1]

  tags = {
    Environment = "production"
  }
}

# Instances

data "aws_ami" "ubuntu" {
  most_recent = true
}

resource "aws_instance" "FrontEnd1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  security_groups = [aws_security_group.FrontEndSG.id]
  subnet_id = [aws_default_subnet.default_az1]
  user_data = "${file("installnginx.sh")}"

  tags = {
    Name = "FrontEnd1"
  }
}

resource "aws_instance" "FrontEnd2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  security_groups = [aws_security_group.FrontEndSG.id]
  subnet_id = [aws_default_subnet.default_az2]
  user_data = "${file("installnginx.sh")}"

  tags = {
    Name = "FrontEnd2"
  }
}