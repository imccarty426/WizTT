################################################################################################
#This section creates the infrastructure for the Tech Task resources
################################################################################################
provider "aws" {
  region = "us-east-2"
}
resource "aws_vpc" "wiztt_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.wiztt_vpc.id
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
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
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
resource "aws_key_pair" "wiztt_ssh" {
  key_name   = "wiztt_ssh"
  public_key = file("./keys/wiztt_public.pub")
}
################################################################################################
# This section creates the VM, installs MongoDB and assigns the high permissions to the VM
################################################################################################
# Creates the Policy for the Wiz tech task with permissions to create and delete VMs
resource "aws_iam_policy" "wiztt_create_delete_vm" {
  name = "VMPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["ec2:RunInstances", "ec2:TerminateInstances"],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}
#Creates a role that can be assumed by any ec2 instance
resource "aws_iam_role" "wiztt_mongodb_vm" {
  name = "MongoVMHighPermissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "wiztt_create_delete_vm_attachment" {
  policy_arn = aws_iam_policy.wiztt_create_delete_vm.arn
  role       = aws_iam_role.wiztt_mongodb_vm.name
}
resource "aws_instance" "mongo_vm" {
  ami           = "ami-0c59e1c7ac3ddd66d"  #old linix ami: amzn2-ami-kernel-5.10-hvm-2.0.20211001.1-x86_64-ebs
  instance_type = "t2.large"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.wiztt_public.id]
  key_name = "wiztt_ssh"

  iam_instance_profile = aws_iam_role.wiztt_mongodb_vm.name #assumes the high permission role

  tags = {
    Name = "wiztt"
  }
}
# install MongoDB package
resource "null_resource" "provision_mongo" {
  triggers = {
    instance_id = aws_instance.mongo_vm.id
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable mongodb4.4",
      "sudo yum install -y mongodb-org"]  # use aws package manager for outdated mongo db install
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./Keys/wiztt_private.pem")
      host        = aws_instance.mongo_vm.public_ip
    }
  }
}
################################################################################################
# This section creates the S3 bucket
################################################################################################
output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}
output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}
output "mongo_vm_ip" {
  value = aws_instance.mongo_vm.public_ip
}