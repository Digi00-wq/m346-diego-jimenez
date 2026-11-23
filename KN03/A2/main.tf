# KN03 A2: Der Zyklus init -> plan -> apply -> destroy mit einer einzigen Ressource

# terraform-Block: Einstellungen für OpenTofu selbst (nicht für AWS)
terraform {
  # Liste der Provider (Plugins), die dieses Projekt braucht; tofu init lädt sie nach .terraform/ herunter
  required_providers {
    # lokaler Name "aws", über den die Ressourcen aws_* diesem Provider zugeordnet werden
    aws = {
      source  = "hashicorp/aws" # Herkunft des Providers in der Registry (Namespace/Name)
      version = "~> 5.0"        # nur Versionen 5.x erlauben, damit ein Major-Update die Konfiguration nicht bricht
    }
  }
}

# provider-Block: Konfiguration des AWS-Providers
provider "aws" {
  region = "us-east-1" # Region, in der alle Ressourcen erstellt werden (das Learner Lab erlaubt nur us-east-1)
  # Keine Credentials hier! Der Provider liest sie automatisch aus ~/.aws/credentials (ausserhalb des Repos)
}

# resource-Block: eine Security Group (Firewall auf Instanz-Ebene)
# "aws_security_group" = Ressourcentyp, "kn03_sg" = lokaler Name, über den andere Blöcke sie referenzieren können
resource "aws_security_group" "kn03_sg" {
  name        = "KN03-SG-Diego"                  # Name der Security Group in AWS (Pflichtfeld, eindeutig pro VPC)
  description = "KN03 A2 - SSH und HTTP erlaubt" # Beschreibung der Gruppe; eine Änderung erzwingt einen Ersatz (-/+)

  # Eingehende Regel 1: SSH
  ingress {
    description = "SSH Zugriff" # Beschreibung der Regel (in Schritt 6 von "SSH" geändert -> ~ update in-place)
    from_port   = 22            # erster erlaubter Port des Bereichs
    to_port     = 22            # letzter erlaubter Port des Bereichs (gleich = genau ein Port)
    protocol    = "tcp"         # SSH läuft über TCP
    cidr_blocks = ["0.0.0.0/0"] # erlaubte Quell-Adressen: 0.0.0.0/0 = das ganze Internet
  }

  # Eingehende Regel 2: HTTP
  ingress {
    description = "HTTP"        # Beschreibung der Regel
    from_port   = 80            # HTTP-Port
    to_port     = 80            # nur Port 80
    protocol    = "tcp"         # HTTP läuft über TCP
    cidr_blocks = ["0.0.0.0/0"] # Webserver soll von überall erreichbar sein
  }

  # Ausgehende Regel: alles erlauben (z. B. für apt-get bei einer späteren Instanz)
  egress {
    from_port   = 0             # 0 bis 0 zusammen mit protocol -1 bedeutet "alle Ports"
    to_port     = 0             # siehe oben
    protocol    = "-1"          # -1 = alle Protokolle (TCP, UDP, ICMP, ...)
    cidr_blocks = ["0.0.0.0/0"] # zu allen Zieladressen
  }

  # Tags sind Schlüssel-Wert-Paare an der Ressource; der Tag "Name" wird im AWS-GUI in der Spalte "Name" angezeigt
  tags = {
    Name = "KN03-SG-Diego" # macht im Screenshot eindeutig sichtbar, dass ich die Gruppe erstellt habe
  }
}
