# KN03 D: Korrigierte Version von review-config.tf (Datenbank-Server)
# Nicht ausgeführt - nur zur Abgabe. Die Nummern (P1, P2, ...) verweisen auf die Review im README.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # P7: Provider-Version festgelegt, damit ein neuer Major-Release nichts unbemerkt ändert
    }
  }
}

provider "aws" {
  region = "us-east-1" # P4: das Learner Lab erlaubt nur us-east-1 (vorher eu-central-1)
  # P1: KEINE access_key/secret_key im Code. Credentials kommen aus ~/.aws/credentials.
}

# Die Datenbank soll nur vom Webserver erreichbar sein. Dazu bekommt der Webserver eine eigene
# Security Group, auf die sich die DB-Regel bezieht (statt einer IP-Adresse oder 0.0.0.0/0).
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for the web server"

  ingress {
    description = "HTTP from internet"
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

resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Security group for the database server"

  # P2: MySQL/MariaDB nur von Instanzen mit der Webserver-Security-Group, nie von 0.0.0.0/0
  ingress {
    description     = "MySQL/MariaDB only from web server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # P6: SSH nur von einer bekannten Admin-Adresse statt aus dem ganzen Internet
  ingress {
    description = "SSH from admin IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # nötig für apt-Updates; produktiv über einen NAT-Gateway
  }

  tags = {
    Name = "database-sg"
  }
}

# P6: Admin-Adresse als Variable, damit sie nicht im Code fest verdrahtet ist (Wert z. B. in terraform.tfvars, nicht im Git)
variable "admin_cidr" {
  description = "Eigene öffentliche IP im CIDR-Format, z. B. 203.0.113.10/32"
  type        = string
}

resource "aws_instance" "database" {
  ami           = "ami-0c30b7300f5fb34cd" # P5: Ubuntu Server 26.04 LTS für us-east-1 (alte ID war aus einer anderen Region und veraltet)
  instance_type = "t3.micro"              # P8: aktuelle Generation wie im restlichen KN (vorher t2.micro)

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # P3: Die Datenbank bekommt keine öffentliche IP und ist nur intern (privates Netz) erreichbar.
  # Im Learner Lab (nur Default-VPC) erreicht man sie für SSH dann über einen Jump-Host (den Webserver).
  associate_public_ip_address = false

  # P9: Ohne Installation und ohne Schlüssel "läuft" kein Datenbank-Server.
  # cloud-init installiert MariaDB und verteilt die SSH-Schlüssel.
  user_data                   = file("cloud-init-db.yaml")
  user_data_replace_on_change = true

  # P10: Root-Volume verschlüsseln, da auf einem DB-Server Daten liegen
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "database-server"
  }
}
