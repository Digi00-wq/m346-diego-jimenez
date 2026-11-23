# KN03 B: Umgebung aus KN02 Teil C komplett als Code (Security Group + Instanz + cloud-init)

# Security Group = Firewall auf Instanz-Ebene
# Typ "aws_security_group", lokaler Name "web_sg" (darüber referenziert die Instanz die Gruppe)
resource "aws_security_group" "web_sg" {
  name        = "KN03-SG-Diego"                   # Name der Gruppe in AWS (eindeutig pro VPC)
  description = "KN03 B - SSH und HTTP eingehend" # Beschreibung; eine Änderung würde die Gruppe ersetzen (-/+)

  # Eingehend: SSH, damit ich mich mit meinem Schlüssel einloggen kann
  ingress {
    description = "SSH"         # Beschreibung der Regel
    from_port   = 22            # Port-Bereich Anfang
    to_port     = 22            # Port-Bereich Ende (nur Port 22)
    protocol    = "tcp"         # SSH nutzt TCP
    cidr_blocks = ["0.0.0.0/0"] # von überall (im Schulkontext ok, produktiv auf die eigene IP einschränken)
  }

  # Eingehend: HTTP für einen späteren Webserver
  ingress {
    description = "HTTP"        # Beschreibung der Regel
    from_port   = 80            # HTTP-Port
    to_port     = 80            # nur Port 80
    protocol    = "tcp"         # HTTP nutzt TCP
    cidr_blocks = ["0.0.0.0/0"] # öffentlich erreichbar
  }

  # Ausgehend: alles erlaubt, damit die Instanz z. B. Pakete via apt herunterladen kann (nötig für cloud-init)
  egress {
    from_port   = 0             # 0-0 mit Protokoll -1 = alle Ports
    to_port     = 0             # siehe oben
    protocol    = "-1"          # -1 = alle Protokolle
    cidr_blocks = ["0.0.0.0/0"] # zu jedem Ziel
  }

  # Name-Tag, wird im AWS-GUI in der Spalte "Name" angezeigt
  tags = {
    Name = "KN03-SG-Diego"
  }
}

# EC2-Instanz (virtuelle Maschine)
# Typ "aws_instance", lokaler Name "web"
resource "aws_instance" "web" {
  # Ubuntu Server 26.04 LTS (Resolute Raccoon), amd64, Build 20261120, Region us-east-1
  # nachgeschlagen im Ubuntu Cloud Image Locator / EC2 AMI Catalog; in einer anderen Region existiert diese ID nicht
  ami           = "ami-0c30b7300f5fb34cd"
  instance_type = "t3.micro" # 2 vCPU, 1 GiB RAM (amd64, passt zum AMI)

  # Referenz auf die Security Group oben statt einer hartcodierten ID (sg-...).
  # Die ID existiert erst nach dem Erstellen der Gruppe; durch die Referenz weiss OpenTofu,
  # dass es zuerst die Security Group und erst danach die Instanz erstellen muss (implizite Abhängigkeit).
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # cloud-init-Konfiguration aus KN02: file() liest die Datei relativ zum Projektordner ein
  # und übergibt ihren Inhalt als User Data. Die SSH-Schlüssel kommen von hier, darum braucht es kein key_name.
  user_data = file("cloud-init-template.yaml")

  # User Data wird von cloud-init nur beim ersten Boot ausgeführt. Ohne diese Zeile würde der AWS-Provider
  # eine geänderte User Data nur hinterlegen (Instanz stoppen/starten, in-place), cloud-init würde sie aber nie anwenden.
  # true = bei einer Änderung wird die Instanz zerstört und neu erstellt (-/+), damit die neue Konfiguration greift.
  user_data_replace_on_change = true

  # Name-Tag der Instanz (ein Tag kann über die API geändert werden -> ~ update in-place)
  tags = {
    Name = "KN03-Diego-Webserver" # in B2 von "KN03-Diego" geändert
  }
}
