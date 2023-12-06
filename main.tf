
//Author Sriram and KiranRaj

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    } 
  }
}

#data "template_file" "user_data"{
#  template = file("user_data.ps1")
#}


provider "aws" {
  region = "us-east-1"
  access_key = "AKIAU3U7QCLJ7VKWD6MI"
  secret_key = "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"
}

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair"
}

resource "aws_vpc" "VPCFROMTF" {
  cidr_block = "10.0.0.0/16" 
  tags = {
        Name = "TFVPC"
  }
}

  resource "aws_subnet" "SUBNETONEFROMTF" {
    cidr_block = var.Subnet1
    availability_zone = "us-east-1a" 
    vpc_id= aws_vpc.VPCFROMTF.id
  tags = {
        Name = "TFSUBNET1a"
  }
    
  }
resource "aws_subnet" "SUBNETFROMTF" {
  cidr_block = var.Subnet
  availability_zone = "us-east-1b" 
  vpc_id= aws_vpc.VPCFROMTF.id
  tags = {
        Name = "TFSUBNET1b"
  }
  
}

data aws_subnet Subnetec2{
id = aws_subnet.SUBNETONEFROMTF.id
}

resource "aws_internet_gateway" "IGWFROMTF" {
  #Name="IGWFROMTF"
  vpc_id = aws_vpc.VPCFROMTF.id

  tags = {
    "name" = "TFIGW"
  }
  
}


/* //Create a simple AD
resource "aws_directory_service_directory" "bar" {
  name     = "India.com"
  password = "Travel@2020"
  size     = "Small"

  vpc_settings {
    vpc_id     = aws_vpc.VPCFROMTF.id
    subnet_ids = [aws_subnet.SUBNETONEFROMTF.id, aws_subnet.SUBNETFROMTF.id]
  }

  tags = {
    Project = "SimpleAD"
  }
} */

//Create a IAM role with 3 policy attached.



resource "aws_iam_role" "ec2-ssm-role" {
name = "EC2SSMROLE"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF

}


resource "aws_iam_role_policy_attachment" "AmazonSSMFullAccess" {
  role       = aws_iam_role.ec2-ssm-role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMDirectoryServiceAccess" {
  role       = aws_iam_role.ec2-ssm-role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.ec2-ssm-role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2-ssm-role" {
  name = "ec2-ssm-role"
  role = aws_iam_role.ec2-ssm-role.name
}

# First windows
//Create an EC2 instance windows

resource "aws_instance" "EC2FROMTF" {
  #name="EC2FROMTF"
  ami = "ami-0cd601a22ac9e6d79"
  subnet_id = aws_subnet.SUBNETFROMTF.id
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm-role.name
  instance_type = "t2.micro"
  associate_public_ip_address = true
 #user_data = base64encode(file("${"userdata.txt"}"))


  tags ={
  Name="Win-1"
}
}

#2nd Windows server

resource "aws_instance" "Win-2" {
  ami = "ami-0cd601a22ac9e6d79"
  subnet_id = aws_subnet.SUBNETFROMTF.id
  instance_type = "t2.micro"
  key_name = "tf-key-pair"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm-role.name
  #user_data = base64encode(file("${"userdata.txt"}" )) 
  tags ={
  Name="Win-2"
}
}

#3rd Windows server
resource "aws_instance" "Win-3" {
  ami = "ami-0cd601a22ac9e6d79"
  subnet_id = aws_subnet.SUBNETFROMTF.id
  instance_type = "t2.micro"
  key_name = "tf-key-pair"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm-role.name
#user_data = base64encode(file("${"userdata.txt"}" ))

  tags ={
  Name="Win-3"
}
}


/* //Domain Join
resource "aws_ssm_document" "ssm_document" {
  name          = "ssm_document_example.com"
  document_type = "Command"
  content       = <<DOC
{
    "schemaVersion": "1.0",
    "description": "Automatic Domain Join Configuration",
    "runtimeConfig": {
        "aws:domainJoin": {
            "properties": {
                "directoryId": "${aws_directory_service_directory.bar.id}",
                "directoryName": "India.com",
                "dnsIpAddresses": ${jsonencode(aws_directory_service_directory.bar.dns_ip_addresses)}
            }
        }
    }
}
DOC
} 

resource "aws_ssm_association" "associate_ssm" {
  name        = aws_ssm_document.ssm_document.name
 
  targets {
    key    = "InstanceIds"
    values = [aws_instance.EC2FROMTF.id]
  }
} */

//SG group :

resource "aws_security_group" "allow_full" {
  name        = "allow_full"
  description = "Full open"
  vpc_id      = aws_vpc.VPCFROMTF.id

  ingress {
    description      = "allow_full"
    from_port        = 0
    to_port          = 0
    protocol         = -1
      cidr_blocks      = ["0.0.0.0/0"]
  }
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    tags = {
    Name = "allow_All"
  }
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.allow_full.id
  network_interface_id = aws_instance.EC2FROMTF.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment2" {
  security_group_id    = aws_security_group.allow_full.id
  network_interface_id = aws_instance.Win-3.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment3" {
  security_group_id    = aws_security_group.allow_full.id
  network_interface_id = aws_instance.Win-2.primary_network_interface_id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.VPCFROMTF.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGWFROMTF.id
  }

  tags = {
    Name = "RT"
  }
}


resource "aws_route_table_association" "RTA" {
  subnet_id      = aws_subnet.SUBNETFROMTF.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.SUBNETONEFROMTF.id
  route_table_id = aws_route_table.RT.id
}

/*module "example" {
source = "git::https://github.com/sriramkausik/EC2.git"
ami_value = "ami-053b0d53c279acc90"
instance_type_value = "t3.micro"
subnet_id_value = data.aws_subnet.Subnetec2.id

  }*/


module "examplee" {
source = "git::https://github.com/sriramkausik/EC2.git"
ami_value = var.ami_valuee
instance_type_value = var.instance_type_valuee
subnet_id_value = aws_subnet.SUBNETONEFROMTF.id
  }