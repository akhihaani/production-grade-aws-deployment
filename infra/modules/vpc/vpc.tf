# VPC

resource "aws_vpc" "memos_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

# Subnets

resource "aws_subnet" "memos_subnet_1" {
  vpc_id                  = aws_vpc.memos_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = var.tags
}

resource "aws_subnet" "memos_subnet_2" {
  vpc_id                  = aws_vpc.memos_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"

  tags = var.tags
}

resource "aws_subnet" "memos_subnet_3" {
  vpc_id                  = aws_vpc.memos_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}c"

  tags = var.tags
}

# IGW
resource "aws_internet_gateway" "memos_igw" {
  vpc_id = aws_vpc.memos_vpc.id

  tags = var.tags
}


# Route Table
resource "aws_route_table" "memos_vpc_route_table" {
  vpc_id = aws_vpc.memos_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.memos_igw.id
  }

  tags = var.tags
}

resource "aws_route_table_association" "memos_route_table_assoc_subnet1" {
  subnet_id      = aws_subnet.memos_subnet_1.id
  route_table_id = aws_route_table.memos_vpc_route_table.id
}

resource "aws_route_table_association" "memos_route_table_assoc_subnet2" {
  subnet_id      = aws_subnet.memos_subnet_2.id
  route_table_id = aws_route_table.memos_vpc_route_table.id
}

resource "aws_route_table_association" "memos_route_table_assoc_subnet3" {
  subnet_id      = aws_subnet.memos_subnet_3.id
  route_table_id = aws_route_table.memos_vpc_route_table.id
}

# Security Group
resource "aws_security_group" "memos_alb_sg" {
  name        = "memos-alb-sg"
  description = "Allow port 443 traffic to alb"
  vpc_id      = aws_vpc.memos_vpc.id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "memos_alb_sg_ingress_port80" {
  security_group_id = aws_security_group.memos_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "memos_alb_sg_ingress_port443" {
  security_group_id = aws_security_group.memos_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "memos_alb_sg_egress_task" {
  security_group_id            = aws_security_group.memos_alb_sg.id
  referenced_security_group_id = aws_security_group.memos_ecs_task_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8081
  to_port                      = 8081
}

resource "aws_security_group" "memos_ecs_task_sg" {
  name        = "memos-ecs-task-sg"
  description = "Allow traffic from alb to port 8081 of container/task"
  vpc_id      = aws_vpc.memos_vpc.id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "memos_ecs_task_sg_ingress_alb" {
  security_group_id            = aws_security_group.memos_ecs_task_sg.id
  referenced_security_group_id = aws_security_group.memos_alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8081
  to_port                      = 8081
}

resource "aws_vpc_security_group_egress_rule" "memos_ecs_task_sg_egress_internet" {
  security_group_id = aws_security_group.memos_ecs_task_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}