terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
    required_version = ">= 1.2.0"

    provider "aws" {
        region = "us-east-1"
    }

    # Create VPC
    resource "aws_vpc" "Assign4VPC" {
        cidr_block           = var.vpc_cidr
        enable_dns_support   = true
        enable_dns_hostnames = true
    }

    # Create public subnets
    resource "aws_subnet" "public_subnet1" {
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.public_subnet1_cidr
        map_public_ip_on_launch = true
        availability_zone = "us-east-1a"
    }

    resource "aws_subnet" "public_subnet2" {
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.public_subnet2_cidr
        map_public_ip_on_launch = true
        availability_zone = "us-east-1b"
    }

    # Create private subnets
    resource "aws_subnet" "private_subnet1" {
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.private_subnet1_cidr
        availability_zone = "us-east-1a"
    }

    resource "aws_subnet" "private_subnet2" {
        vpc_id            = aws_vpc.main.id
        cidr_block        = var.private_subnet2_cidr
        availability_zone = "us-east-1b"
    }

    # Internet Gateway
    resource "aws_internet_gateway" "Assign4IG" {
        vpc_id = aws_vpc.main.id
    }

    # Route Table for public subnets
    resource "aws_route_table" "publicRT" {
        vpc_id = aws_vpc.main.id

        route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.igw.id
        }
    }

    # Associate public subnets with the route table
    resource "aws_route_table_association" "public_subnet1" {
        subnet_id      = aws_subnet.public_subnet1.id
        route_table_id = aws_route_table.public.id
    }

    resource "aws_route_table_association" "public_subnet2" {
        subnet_id      = aws_subnet.public_subnet2.id
        route_table_id = aws_route_table.public.id
    }

    # Security Group for web servers
    resource "aws_security_group" "web_sg" {
        vpc_id = aws_vpc.main.id

        ingress {
            from_port   = 80
            to_port     = 80
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

    # Security Group for RDS
    resource "aws_security_group" "rds_sg" {
        vpc_id = aws_vpc.main.id

        ingress {
            from_port       = 3306
            to_port         = 3306
            protocol        = "tcp"
            security_groups = [aws_security_group.web_sg.id]
        }

        egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    # Launch EC2 instances in public subnets
    resource "aws_instance" "web1" {
        ami                    = "ami-08d70e59c07c61a3a"
        instance_type          = "t2.micro"
        subnet_id              = aws_subnet.public_subnet1.id
        security_groups        = [aws_security_group.web_sg.name]
        tags = {
            Name = var.instance1_name
        }
    }

    resource "aws_instance" "web2" {
        ami                    = "ami-08d70e59c07c61a3a"
        instance_type          = "t2.micro"
        subnet_id              = aws_subnet.public_subnet2.id
        security_groups        = [aws_security_group.web_sg.name]
        tags = {
            Name = var.instance2_name
        }
    }

    # RDS Subnet Group
    resource "aws_db_subnet_group" "rds_subnet_group" {
        name       = "rds-subnet-group"
        subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
    }

    # RDS Instance
    resource "aws_db_instance" "rds" {
        allocated_storage    = 20
        engine               = "mysql"
        engine_version       = "8.0"
        instance_class       = "db.t2.micro"
        name                 = "Assign4DB"
        db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
        vpc_security_group_ids = [aws_security_group.rds_sg.id]
    }
}
