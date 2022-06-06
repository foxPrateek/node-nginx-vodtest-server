
terraform {
     required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
     docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }

  }
 
  required_version = "~> 1.2.1"
}


provider "aws" {
  region = "${var.aws_region}"
}


provider "docker" {
  host = "tcp://${aws_instance.web.public_ip}:2376/"
}

/*

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "website-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

*/
resource "aws_security_group" "allow_web" {
  name = "allow_http"
  description = "Allow http and ssh inbound traffic"
//  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.app_data_bucket_name}"
  force_destroy = true
  tags = {
   Name   = "APP data bucket"
  }
}


resource "aws_s3_bucket_object" "app_data" {
  bucket = aws_s3_bucket.data_bucket.id
  for_each = fileset(var.local_data_dir, "**")
  key    = "${var.local_data_dir}/${each.value}"
  source = "${var.local_data_dir}/${each.value}"
  etag = filemd5("${var.local_data_dir}/${each.value}")
}



resource "aws_instance" "web" {
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_type}"
  //count = "1"
  associate_public_ip_address = "true"
  key_name = "testkey"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  //security_groups = ["${aws_security_group.allow_web.name}"]
  vpc_security_group_ids = ["${aws_security_group.allow_web.id}"]
  //subnet_id = "${aws_subnet.default.id}"
  tags =  {
    Name = "TestServer"
    Product = "Docker Nginx and Node"
  }
   user_data = "${file("./execute.sh")}"
   user_data_replace_on_change = "true"  
   depends_on = [ aws_s3_bucket_object.app_data ]
}


/*resource "null_resource" "copy_data" {

    connection {
    type = "ssh"
    host = aws_instance.web.public_ip
    user = "ubuntu"
    private_key = "${file("testkey")}"
    }

  provisioner "file" {
    source      = "./app"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = "/home/ubuntu/node-nginx-aws-terraform/docker-compose.yml"
    destination = "/home/ubuntu"
  }

  provisioner "file" {
    source      = "/home/ubuntu/node-nginx-aws-terraform/nginx/"
    destination = "/home/ubuntu"
  }

provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo snap install docker",
      "sudo docker-compose up -d --scale web=1"
    ]
  }

  depends_on = [ aws_instance.web ]

  }

*/
//module "docker" {
//  source = "./docker"
//  aws_ip = "${module.aws.public_ip}"
//}
