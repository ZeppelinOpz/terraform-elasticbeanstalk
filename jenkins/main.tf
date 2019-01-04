provider "aws" {  
  region  = "us-east-1"
  profile = "your_aws_profile"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private-key to key/xxx.pem
resource "local_file" "ssh_key_private" {
  content  = "${tls_private_key.ssh.private_key_pem}"
  filename = "${path.module}/keys/sandbox-ops.pem"
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/keys/sandbox-ops.pem"
  }
}

# Create key-pair at amazon with given public-key & key-name
resource "aws_key_pair" "generated_key" {
  key_name   = "ops"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

variable "max_availability_zones" {
  default = "3"
}

data "aws_availability_zones" "available" {}

module "jenkins" {
  source      = "./modules/terraform-aws-jenkins"
  namespace   = "cp"
  name        = "jenkins"
  stage       = "dev"
  description = "Jenkins server as Docker container running on Elastic Beanstalk"

  master_instance_type         = "t2.large"
  aws_account_id               = ""
  aws_region                   = "us-east-1"
  availability_zones           = ["${slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones)}"]
  vpc_id                       = "vpc-0fa142f8f6f21be9d"
  zone_id                      = "Z21SGFL51ZXD1B"
  public_subnets               = ["subnet-0cf1db42ed7dfd272","subnet-008a0fda2e2281236","subnet-06c42b18d56e3c5a7"]
  private_subnets              = ["subnet-0066061d661ba8b2e","subnet-0993a1be5a2be98b3","subnet-0781c63ed7489c858"]
  loadbalancer_certificate_arn = ""
  ssh_key_pair                 = "${aws_key_pair.generated_key.key_name}"

  root_volume_size = "200"
  root_volume_type = "standard"

  github_oauth_token  = "put git_public_access_token"
  github_organization = "ZeppelinOpz"
  github_repo_name    = "jenkins"
  github_branch       = "master"

  datapipeline_config = {
    instance_type = "t2.medium"
    email         = "rtinoco@cisco.com"
    period        = "12 hours"
    timeout       = "60 Minutes"
  }

  env_vars = {
    JENKINS_USER          = "admin"
    JENKINS_PASS          = "start12!"
    JENKINS_NUM_EXECUTORS = 4
  }

  tags = {
    BusinessUnit = "Build"
    Department   = "Ops"
  }
}
