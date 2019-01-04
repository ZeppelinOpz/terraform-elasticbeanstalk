provider "aws" {
  region = "us-east-1"
  profile = "your_aws_profile"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private-key to key/xxx.pem
resource "local_file" "ssh_key_private" {
  content  = "${tls_private_key.ssh.private_key_pem}"
  filename = "${path.module}/keys/sandbox-demo.pem"
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/keys/sandbox-demo.pem"
  }
}

# Create key-pair at amazon with given public-key & key-name
resource "aws_key_pair" "generated_key" {
  key_name   = "demo"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}


variable "max_availability_zones" {
  default = "3"
}

data "aws_availability_zones" "available" {}

module "elasticbeanstalk-demo" {
  source      = "../"
  namespace   = "zeppelinops"
  name        = "app"
  stage       = "demo"
  description = "Demo application as Multi Docker container running on Elastic Beanstalk"

  master_instance_type         = "t2.small"
  aws_account_id               = ""
  aws_region                   = "us-east-1"
  availability_zones           = ["${slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones)}"]
  vpc_id                       = "your_vpc_id"
  zone_id                      = "your_rout53_hosted_zone_id"
  public_subnets               = ["your_public_subnet_1","your_public_subnet_2","your_public_subnet_3"]
  private_subnets              = ["your_private_subnet_1","your_private_subnet_2","your_private_subnet_2"]
  loadbalancer_certificate_arn = ""
  ssh_key_pair                 = "${aws_key_pair.generated_key.key_name}"
  solution_stack_name          = "64bit Amazon Linux 2018.03 v2.11.6 running Multi-container Docker 18.06.1-ce (Generic)"

  env_vars = {
  }

  tags = {
    BusinessUnit = "Demo"
    Department   = "Ops"
  }
}
