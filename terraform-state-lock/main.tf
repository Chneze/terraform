provider "aws" {
   region     = "us-east-1"
   access_key = var.access_key
   secret_key = var.secret_key
}

resource "aws_instance" "ec2_web" {
    ami = "ami-0c614dee691cbbf37"
    instance_type = "t2.micro"
    tags = {
      Name = "EC2 Instance with remote state"
    }
}

terraform {
    backend "s3" {
        bucket = "henokk-terraform-s3-bucket"
        key    = "henok/terraform/remote/s3/terraform.tfstate"
        region     = "us-east-1"
        dynamodb_table = "dynamodb-state-locking"
    }
}
