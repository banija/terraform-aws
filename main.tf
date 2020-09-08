provider "aws" {
    region = var.aws_region
}

resource "aws_vpc" "test_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "test_cidr_block"
    }
}

resource "aws_internet_gateway" "test_vpc_gateway" {
    vpc_id = aws_vpc.test_vpc.id
}

resource "aws_subnet" "test_subnet" {
    vpc_id = aws_vpc.test_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.aws_availabilty_zone
}

resource "aws_route_table" "default_gateway" {
    vpc_id = aws_vpc.test_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.test_vpc_gateway.id
    }
}

resource "aws_route_table_association" "default_association" {
    subnet_id = aws_subnet.test_subnet.id
    route_table_id = aws_route_table.default_gateway.id
}

resource "aws_network_acl" "allowall" {
    vpc_id = aws_vpc.test_vpc.id

   egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all  traffic"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "webserver"{
    instance = aws_instance.webserver.id
    vpc = true
    depends_on = [aws_internet_gateway.test_vpc_gateway]
}

resource "aws_key_pair" "goran_public_key" {
    key_name = "ec2_ssh_key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDaprsgWYtATbf2NSVVrxCIVqazaAYMipvmDMvG3i/KW2z0fmkSDHL2mRCvayzC2RFpAV7jb/13dcASVJvW8HgrTOSKimq7OpmvM1SjbExKZhioGJ2oLdPr6AidBbaFEr3jj9wDIu8m8V89UGEyhfuMloAV9S1NrDMmrgWURU4RH8t3HE8T19c33/oEIs3+c6WiBqbmmrpy7imakioBJCpOtDYnxB1zE4w1O3lGE9o9y+oitmsdQBHGIoM0j2CRQFaX6Cs7N76cIoqvXxXgYOzGbT2XSyzJu/QnLZUZ8mHaT87W8TKOjiiESwMTUdC27QDPQyD9mJWYbkkYaS2R/m0+WwgZ/8YSHnnXDDg0u4JM9D/SHJ14HDnSarIsmsMZZtk49PXADKq14XnNPJ7OkKS+3BmxdFP3XsTigSKjooMxiDWOC7bpuJbou4tfX6H7y2YXWFIwI+AHKlXDfOfIvoO7B35oyijNiblxkyr3tVNkwI2QCNaVbXRDJZO0w4/1lc= goran.markovic@Gorans-MacBook-Pro.local"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
       name   = "virtualization-type"
       values = ["hvm"]
  }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "webserver" {
    ami = data.aws_ami.ubuntu.id
    availability_zone = var.aws_availabilty_zone
    instance_type = "t2.micro"
    key_name = aws_key_pair.goran_public_key.key_name
    vpc_security_group_ids = [aws_security_group.allow_all.id]
    subnet_id = aws_subnet.test_subnet.id
}
