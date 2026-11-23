# KN03 B: Outputs = Werte, die nach tofu apply ausgegeben werden (auch später mit "tofu output")

# Öffentliche IP der Instanz, damit ich direkt weiss, wohin ich mich per SSH verbinde
output "public_ip" {
  description = "Oeffentliche IPv4-Adresse der KN03-Instanz" # Beschreibung des Outputs
  value       = aws_instance.web.public_ip                   # Attribut public_ip der Ressource aws_instance.web (bekannt erst nach dem Erstellen)
}
