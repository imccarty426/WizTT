resource "aws_key_pair" "wiztt_ssh" {
  key_name   = "wiztt_ssh"
  public_key = file("./keys/wiztt_public.pub")
}
# Creates the Policy for the Wiz tech task with permissions to create and delete VMs
resource "aws_iam_policy" "wiztt_create_delete_vm_policy" {
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
resource "aws_iam_role" "wiztt_mongodb_vm_role" {
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
resource "aws_iam_role_policy_attachment" "wiztt_create_delete_vm_policy_attachment" {
  policy_arn = aws_iam_policy.wiztt_create_delete_vm_policy.arn
  role       = aws_iam_role.wiztt_mongodb_vm_role.name
}