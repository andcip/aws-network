resource "aws_security_group" "ssh_access" {

  name        = "bastion-ssh-access-sg"
  description = "Security Group to enable ssh remote access"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["62.196.76.0/24"] ## Ingress from assist network
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "default" {
  count = var.acm_key_file != null ? 1 : 0
  key_name   = var.acm_key_name
  public_key = file(var.acm_key_file)
}

resource "aws_instance" "bastion" {

  instance_type          = "t3.micro"
  ami                    = "ami-07df274a488ca9195"
  key_name               = var.acm_key_name
  subnet_id              = var.vpc.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  tags = {
    "Name"      = "BastionHost"
    "Type"      = "bastion"
  }
}
