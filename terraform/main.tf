terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_key_pair" "My_key" {
    key_name   = "My_key"
    public_key = file("../llavepub")  // Path to the public key
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow HTTP and SSH inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

resource "aws_instance" "web" {
  ami             = "ami-0e86e20dae9224db8"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.My_key.key_name
  security_groups = [aws_security_group.web.name]

    tags = {
        Name = "My_instance"
    }

    provisioner "remote-exec" {
      inline = [ "echo wait until SSH is ready" ]

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file("../llaveprivssh.pem") // Path to the private key
        host        = self.public_ip
      }
    }
    provisioner "local-exec" {
      command = " sudo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${aws_instance.web.public_ip}, --private-key ../llaveprivssh.pem ../ansible/nginx.yaml"
    }
}


output "instance_ip" {
  description = "ID de instancia EC2"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "ID de instancia EC2"
  value       = aws_instance.web.public_ip
}