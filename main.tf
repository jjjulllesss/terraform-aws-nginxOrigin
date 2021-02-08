#Get the VPC ID
data "aws_vpc" "selected" {
  tags = {
    Name = var.vpc_name
  }
}

#Get the ID of the latest ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#Get the subnet ID where the instance will be installed
data "aws_subnet_ids" "example" {
  vpc_id = data.aws_vpc.selected.id
}

#Get the infos concerning the VPC (CIDR)
data "aws_vpc" "example" {
  id = data.aws_vpc.selected.id
}

#Modify the startup script
data "template_file" "init" {
  template = "${file("${path.module}/install.sh")}"
}

#########################RESSOURCES###################################
#add random letters to create unique ressources
resource "random_string" "random" {
  length  = 5
  special = false
}

resource "aws_instance" "instance" {
  count                  = length(var.instance_names)
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  availability_zone      = var.aws_az
  vpc_security_group_ids = [aws_security_group.security_group_instance.id]

  #SSH key name
  key_name = var.key_name

  #IAM role attach to the instance
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  #Script to install the Origin server
  user_data = data.template_file.init.rendered

  #Primary storage of the instance
  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_storage
  }

  tags = {
    Name        = "${var.instance_names[count.index]}-${random_string.random.result}"
    Project     = var.tags.project_name
    Officehours = var.tags.officehours
    Owner       = var.tags.owner
    Created_by  = "Terraform"
  }

  volume_tags = {
    Name        = "${var.instance_names[count.index]}-${random_string.random.result}"
    Officehours = var.tags.officehours
    Project     = var.tags.project_name
    Owner       = var.tags.owner
    Created_by  = "Terraform"
  }
}

# # # # # # # # # # # # # # Elastic IP # # # # # # # # # # # # # # #
resource "aws_eip" "elasticip" {
  count = length(var.instance_names)
  vpc   = true
  tags = {
    Name       = "${var.instance_names[count.index]}-${random_string.random.result}"
    Project    = var.tags.project_name
    Owner      = var.tags.owner
    Created_by = "Terraform"
  }
}

resource "aws_eip_association" "eip_assoc" {
  count         = length(var.instance_names)
  instance_id   = aws_instance.instance[count.index].id
  allocation_id = aws_eip.elasticip[count.index].id
}



# # # # # # # # # # # Security group # # # # # # # # # # # # # # # # # #

resource "aws_security_group" "security_group_instance" {
  name        = "sg_origin-${random_string.random.result}"
  description = "Allow http, ping inbound traffic. All in outbound"
  vpc_id      = data.aws_vpc.selected.id

  #Port for SSH access  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Port for HTTP access  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Port for ping inside the VPC
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [data.aws_vpc.example.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "sg_origin-${var.tags.project_name}-${random_string.random.result}"
    Project    = var.tags.project_name
    Owner      = var.tags.owner
    Created_by = "Terraform"
  }
}

#########################IAM###################################

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role-${random_string.random.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm_profile-${random_string.random.result}"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm_policy-${random_string.random.result}"
  role = aws_iam_role.ssm_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}