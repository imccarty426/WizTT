resource "aws_vpc" "wiztt_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.wiztt_vpc.i
  cidr_block              = "10.0.1.0/24"  
  availability_zone      = "us-east-2a"    
  map_public_ip_on_launch = true
}
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.wiztt_vpc.id
  cidr_block              = "10.0.2.0/24"  
  availability_zone      = "us-east-2a"    
}
resource "aws_internet_gateway" "wiztt_internet_gateway" {
  vpc_id = aws_vpc.wiztt_vpc.id
}
resource "aws_nat_gateway" "wiztt_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}
resource "aws_eip" "nat_eip" {
  vpc = true
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.wiztt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wiztt_internet_gateway.id
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.wiztt_nat_gateway.id
}
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.wiztt_vpc.id
}
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_security_group" "wiztt_public" {
  name        = "wiztt-public"
  description = "Security group to allow all traffic"
  vpc_id = aws_vpc.wiztt_vpc.id
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "wiztt_private" {
  name        = "wiztt-private"
  description = "Security group to allow traffic from the private subnet"
  vpc_id = aws_vpc.wiztt_vpc.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.wiztt_public.id]
  }
}