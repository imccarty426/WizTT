resource "aws_instance" "mongo_vm" {
  ami           = "ami-0c59e1c7ac3ddd66d"  #old linix ami: amzn2-ami-kernel-5.10-hvm-2.0.20211001.1-x86_64-ebs
  instance_type = "t2.large"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.wiztt_public.id]
  key_name = "wiztt_ssh"

  iam_instance_profile = aws_iam_role.wiztt_mongodb_vm.name #assumes the high permission role

  user_data = <<EOF
#!/bin/bash
echo "[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl enable mongod
EOF
}