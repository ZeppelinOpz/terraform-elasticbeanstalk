# How to Create 

## Create Hosted Zone 

Goto aws Route53 and create a empty hosted zone

Take note the id of zone

## Create Token With Public Access For Jenkins

https://github.com/ZeppelinOpz/jenkins

![Alt text](images/token.png?raw=true "Title")

Take note the token

## Create Vpc

Goto vpc directory

Upadate the variables inside main.tf

- your_aws_profile

 Run :

```bash
terraform init
terraform apply
```

Take note of the vpc.id , public subnets id , private subnets id from output

## Create Jenkins

Goto jenkins directory

Upadate the variables inside main.tf

- your_aws_profile
- your_vpc_id
- your_rout53_hosted_zone_id
- your_public_subnet_* (1,2,3) 
- your_private_subnet_* (1,2,3)
- github_* (jenkins docker repository settings & token)

```bash
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
  vpc_id                       = "your_vpc_id"
  zone_id                      = "your_rout53_hosted_zone_id"
  public_subnets               = ["your_public_subnet_1","your_public_subnet_2","your_public_subnet_3"]
  private_subnets              = ["your_private_subnet_1","your_private_subnet_2","your_private_subnet_2"]
  loadbalancer_certificate_arn = ""
  ssh_key_pair                 = "${aws_key_pair.generated_key.key_name}"

  root_volume_size = "100"
  root_volume_type = "standard"

  github_oauth_token  = "put git_public_access_token"
  github_organization = "ZeppelinOpz"
  github_repo_name    = "jenkins"
  github_branch       = "master"

  datapipeline_config = {
    instance_type = "t2.medium"
    email         = "rtinoco@zeppelinops.com"
    period        = "12 hours"
    timeout       = "60 Minutes"
  }

  env_vars = {
    JENKINS_USER          = "dummy"
    JENKINS_PASS          = "DummyPassword123!"
    JENKINS_NUM_EXECUTORS = 4
  }

  tags = {
    BusinessUnit = "Build"
    Department   = "Ops"
  }
}
```

 Run :

```bash
terraform init
terraform apply
```

## Create Environments 

Goto environments/example directory

Upadate the variables inside main.tf

- your_aws_profile
- your_vpc_id
- your_rout53_hosted_zone_id
- your_public_subnet_* (1,2,3) 
- your_private_subnet_* (1,2,3)


```bash
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

```

 Run :

```bash
terraform init
terraform apply
```

# How to Remove

Delete all buckets created with above steps

* First get all buckets

```bash
aws s3 ls | cut -d" " -f 3 > buckets
```

* Modify buckets file, remove the bucket name you want to keep

* Delete buckets

```bash
cat buckets | xargs -I{} aws s3 rb s3://{} --force
```

Then run:

```
terraform destroy
```

for in order : environments,jenkins,vpc
