provider "aws" {
  region = "us-east-1"
}

module "basic_launch_template" {
  source = "../../"

  template_name = "basic-web-server"
  environment   = "dev"
  description   = "Basic launch template for web servers"

  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (update with latest)
  instance_type = "t3.micro"
  key_name      = "my-key-pair"

  vpc_security_group_ids = ["sg-0123456789abcdef0"]

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "Hello from Launch Template" > /var/www/html/index.html
  EOF

  tags = {
    Project = "WebApp"
    Owner   = "DevOps"
  }
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.basic_launch_template.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = module.basic_launch_template.arn
}