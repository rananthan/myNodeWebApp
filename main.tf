terraform {

  cloud {
    organization = "rananthanrayanan_org"

    workspaces {
      name = "tfcli-workspace"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name         = var.ecr_repo_name
  force_delete = true
}

resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my_first_task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my_first_task",
      "image": "819149815528.dkr.ecr.us-east-1.amazonaws.com/my_ecr_repo:1.2",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "arn:aws:iam::819149815528:role/ecsTaskExecutionRole"
}

resource "aws_ecs_service" "my_first_service" {
  name            = var.ecs_service_name                      # Naming our first service
  cluster         = aws_ecs_cluster.my_ecs_cluster.id         # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.my_first_task.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Setting the number of containers we want deployed to 2

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.my_first_task.family
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = ["subnet-0cc572bac1f076425", "subnet-0df74f276d6832bed"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Referencing the security group
  }

}

resource "aws_security_group" "service_security_group" {
  vpc_id = "vpc-02f9937a7d33740de" # Referencing the default VPC
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["sg-089247704a345b3d5"]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "test-lb-tf" # Naming our load balancer
  load_balancer_type = "application"
  subnets            = ["subnet-0cc572bac1f076425", "subnet-0df74f276d6832bed"]
  # Referencing the security group
  security_groups = ["sg-089247704a345b3d5"]
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-02f9937a7d33740de" # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our tagrte group
  }
}

/*
# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {

  vpc_id = "vpc-02f9937a7d33740de" # Referencing the default VPC

  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["72.221.90.104/32"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}
*/