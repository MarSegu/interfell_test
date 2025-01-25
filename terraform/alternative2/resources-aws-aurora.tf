# Aurora Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "transaction-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.11.1"
  master_username         = "admin"
  master_password         = var.aurora_password
  database_name           = "transactions"
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"

  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnets.name

  tags = var.tags
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora_instance" {
  count                = 2 # Two instances for high availability
  identifier           = "transaction-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster.id
  instance_class       = "db.r5.large"
  engine               = aws_rds_cluster.aurora_cluster.engine
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_subnets.name

  tags = var.tags
}

# Aurora Subnet Group
resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags       = var.tags
}

# Aurora Security Group
resource "aws_security_group" "aurora_sg" {
  name_prefix = "aurora-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    #security_groups = [aws_security_group.fargate_sg.id] # Allow Fargate to connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
