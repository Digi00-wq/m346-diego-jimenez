# KN03 B: Provider-Konfiguration (getrennt von den Ressourcen, damit main.tf übersichtlich bleibt)

# terraform-Block: Einstellungen für OpenTofu selbst
terraform {
  # Provider-Plugins, die tofu init herunterlädt (in den Ordner .terraform/)
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Herkunft des Providers in der Registry
      version = "~> 5.0"        # nur 5.x erlauben, damit ein neuer Major-Release nichts kaputt macht
    }
  }
}

# AWS-Provider: legt fest, wo und wie mit AWS gesprochen wird
provider "aws" {
  region = "us-east-1" # das Learner Lab erlaubt nur diese Region; AMI-IDs gelten pro Region
  # Credentials stehen bewusst NICHT hier, sondern in ~/.aws/credentials (Credentials-Routine bei jedem Lab-Start)
}
