# KN02: Cloud-Onboarding & SSH

## Übersicht

| Datei | Zweck |
| --- | --- |
| [cloud-init-kn01.yaml](./cloud-init-kn01.yaml) | C1: meine cloud-init-Datei aus KN01, erweitert um meinen öffentlichen Schlüssel (AWS-Version) |
| [cloud-init-template.yaml](./cloud-init-template.yaml) | C3: mein persönliches Template für alle folgenden KNs |

| Instanz | Teil | Key Pair (GUI) | Öffentliche IP | Benutzer / Schlüssel |
| --- | --- | --- | --- | --- |
| `KN02` | B | `diego1` | `52.91.73.199` | `ubuntu` mit `diego1` |
| `KN02-aufgabe-c` | C | `diego2` | `98.84.173.209` | `ubuntu` mit `diego2`, `diego` mit `diego1` (aus cloud-init) |

Beide Instanzen: Ubuntu Server 26.04, Typ `t3.micro`, Region `us-east-1`.

Die öffentlichen IPs in der Tabelle sind vom 23.11.2026. Am Ende jeder Lab-Session werden die Instanzen gestoppt, und beim nächsten Start vergibt AWS eine **neue öffentliche IP**. Darum zeigen die SSH-Screenshots vom 16.11.2026 andere Adressen (z. B. `ec2-54-144-37-63...`). Die private IP bleibt gleich: `KN02` hat immer `172.31.35.111` (sichtbar im Prompt `ip-172-31-35-111`).

**Hinweis zur Instanz `KN02-aufgabe-c`:** Die ursprüngliche C-Instanz (`i-06771c64fef29e019`, private IP `172.31.37.119`) habe ich am 23.11.2026 zu früh terminiert. Für die korrigierten C1-Nachweise habe ich sie am 23.11.2026 mit genau denselben Einstellungen neu erstellt, diesmal mit OpenTofu statt über das GUI (Wissen aus KN03): gleiches AMI (`ami-0547ecbf0e9b4aeb5`, Ubuntu 26.04), `t3.micro`, Key Pair `diego2`, Security Group `launch-wizard-2` aus KN02 und [cloud-init-kn01.yaml](./cloud-init-kn01.yaml) als User Data. Die neue Instanz heisst wieder `KN02-aufgabe-c` (`i-001989fac113b014a`, private IP `172.31.20.148`). Die C1-Screenshots zeigen diese neue Instanz, die C2-Screenshots stammen noch von der ursprünglichen (`ip-172-31-37-119`).

## A) Learner Lab einrichten

Ich habe den Kurs «AWS Academy Learner Lab» geöffnet und das Lab gestartet. Der grüne Kreis neben «AWS» zeigt, dass das Lab läuft, daneben sieht man das verbrauchte Budget:

![Learner Lab gestartet mit Budget](./img/a_learner_lab.png)

Über den Link «AWS» bin ich in die AWS Management Console gekommen und konnte EC2 öffnen. Rechts oben steht mein Benutzername (`voclabs/user5701727=diego.jimenez@edu.tbz.ch`):

![EC2-Umgebung mit Benutzername](./img/a_ec2_username.png)

## B) SSH-Schlüssel verstehen: das Zwei-Schlüssel-Experiment

### B1) Instanz mit Schlüsselpaar erstellen

Ich habe im GUI zwei Schlüsselpaare `diego1` und `diego2` erstellt und die `.pem`-Dateien nach `~/.ssh/` gelegt (`chmod 400`, sonst verweigert SSH den Schlüssel). Danach habe ich die Instanz `KN02` mit dem Key Pair **`diego1`** erstellt.

### B2) Das Experiment

Instanz-Details von `KN02` (`i-0934296988778e843`): oben die öffentliche IP `52.91.73.199`, weiter unten im Tab *Details* das verwendete Key Pair (`Key pair assigned at launch: diego1`):

![Instanz-Details KN02: öffentliche IP](./img/b2_instance_details_1.png)

![Instanz-Details KN02: Key pair diego1](./img/b2_instance_details_2.png)

Eigenschaften der Instanz. AWS weist dem Instanztyp `t3.micro` und dem Image feste Grössen zu. Im Gast (Ubuntu) ist davon etwas weniger nutzbar, weil das Dateisystem und der Kernel selbst Platz brauchen:

| Was | Zugewiesen (AWS) | Im Gast sichtbar / nutzbar |
| --- | --- | --- |
| Disk | 8 GiB EBS-Volume (gp3, Grösse aus dem Ubuntu-AMI) | 6.61 GB Root-Dateisystem `/` (Login-Meldung «Usage of /: … of 6.61GB») |
| RAM | 1 GiB (Instanztyp `t3.micro`) | 908.63 MiB (`free -h`), der Rest ist vom Kernel und der Firmware reserviert |
| CPU | 2 vCPUs (`t3.micro`: 1 physischer Kern mit 2 Threads) | 2 vCPUs, Modell Intel(R) Xeon(R) Platinum 8259CL |
| Betriebssystem | AMI Ubuntu Server 26.04 (`ami-0547ecbf0e9b4aeb5`) | Ubuntu 26.04.1 LTS (Resolute Raccoon) |

Mit dem **ersten** Schlüssel (`diego1`) konnte ich mich verbinden:

![SSH mit diego1: Erfolg](./img/first_key.png)

Mit dem **zweiten** Schlüssel (`diego2`) wurde die Verbindung abgelehnt (`Permission denied (publickey)`):

![SSH mit diego2: Ablehnung](./img/second_key.png)

**Vergleich Public Key ↔ `authorized_keys`:** Mit `ssh-keygen -y -f ~/.ssh/diego1.pem` habe ich aus dem privaten Schlüssel den öffentlichen Schlüssel berechnet (das geht, weil der öffentliche Schlüssel mathematisch aus dem privaten folgt, aber nicht umgekehrt). Danach habe ich ihn mit `~/.ssh/authorized_keys` des Benutzers `ubuntu` auf dem Server verglichen:

![Vergleich extrahierter Public Key mit authorized_keys](./img/b2_key_compare.png)

Der öffentliche Schlüssel von `diego1` steht genau so in `authorized_keys`, der von `diego2` nicht. Er liegt dort, weil AWS beim Erstellen der Instanz den öffentlichen Teil des im GUI gewählten Key Pairs (`diego1`) in die Instanz übergibt und cloud-init ihn beim ersten Boot in `/home/ubuntu/.ssh/authorized_keys` schreibt. Beim Login prüft der Server, ob ich den passenden privaten Schlüssel besitze. Darum funktioniert nur `diego1.pem`.

## C) Erste Instanz mit cloud-init & Ihr Template

### C1) cloud-init mit SSH-Schlüssel erweitern & Instanz erstellen

Ich habe meine `cloud-init-kn01.yaml` aus KN01 im `users`-Block um meinen öffentlichen Schlüssel `diego1` erweitert ([cloud-init-kn01.yaml](./cloud-init-kn01.yaml)). Die Instanz `KN02-aufgabe-c` habe ich mit dem Key Pair **`diego2`** erstellt und die Datei ins Feld **User data** kopiert.

Instanz-Details von `KN02-aufgabe-c` (`i-001989fac113b014a`): Zustand *Running*, Typ `t3.micro`, öffentliche IP `98.84.173.209` bzw. DNS `ec2-98-84-173-209.compute-1.amazonaws.com`, und weiter unten **Key pair assigned at launch** = `diego2`:

![Instanz-Details KN02-aufgabe-c: öffentliche IP](./img/c1_instance_details_1.png)

![Instanz-Details KN02-aufgabe-c: Key pair diego2](./img/c1_instance_details_2.png)

Für die drei Logins verwende ich den Hostnamen direkt im Befehl (Form `benutzer@hostname`), damit Benutzer, Schlüssel und Instanz eindeutig sichtbar sind.

Login als Standardbenutzer `ubuntu` mit dem **zweiten** Schlüssel (`diego2`, aus dem GUI) mit `ssh -i ~/.ssh/diego2.pem ubuntu@ec2-98-84-173-209.compute-1.amazonaws.com`: funktioniert. Der Prompt zeigt `ubuntu@ip-172-31-20-148`, `whoami` gibt `ubuntu` aus.

![ubuntu mit diego2: Erfolg](./img/ubuntu_login_ssh.png)

Login als mein cloud-init-Benutzer `diego` mit dem **ersten** Schlüssel (`diego1`, aus cloud-init) mit `ssh -i ~/.ssh/diego1.pem diego@ec2-98-84-173-209.compute-1.amazonaws.com`: funktioniert. Der Prompt zeigt `diego@ip-172-31-20-148`, `whoami` gibt `diego` aus.

![diego mit diego1: Erfolg](./img/diego_login_ssh.png)

Login als `diego` mit dem **zweiten** Schlüssel mit `ssh -i ~/.ssh/diego2.pem diego@ec2-98-84-173-209.compute-1.amazonaws.com`: wird mit `Permission denied (publickey)` abgelehnt, weil `diego2` nicht in `/home/diego/.ssh/authorized_keys` steht.

![diego mit diego2: Ablehnung](./img/diego_login_failed.png)

Die beiden Mechanismen beeinflussen sich also nicht: Das Key Pair aus dem GUI gilt nur für den Standardbenutzer `ubuntu`, die Schlüssel aus `ssh_authorized_keys` im cloud-init nur für meinen Benutzer `diego`.

### C2) Nachweise in der laufenden Instanz

Eingeloggt als `diego` mit `diego1` habe ich meine KN01-Erweiterungen geprüft: Die Datei `info.txt` aus `write_files` ist vorhanden, und das Paket `vim` ist installiert (`/usr/bin/vim`):

![KN01-Erweiterungen in der AWS-Instanz](./img/coud_init_testing.png)

Auszug aus dem cloud-init-Log mit dem Befehl `head /var/log/cloud-init-output.log` (derselbe Pfad wie lokal in KN01):

![cloud-init-Log](./img/log_output.png)

### C3) Mein persönliches Template

Datei: [cloud-init-template.yaml](./cloud-init-template.yaml). Gegenüber C1 enthält das Template drei zusätzliche Konfigurationen:

1. **Schlüssel der Lehrperson:** Unter `ssh_authorized_keys` steht neben meinem Schlüssel `diego1` auch der öffentliche Schlüssel der Lehrperson. Das Template enthält also zwei öffentliche Schlüssel, und die Lehrperson kann sich auf meine zukünftigen Instanzen als `diego` einloggen.
2. **Härtung:** `ssh_pwauth: false` schaltet den SSH-Login mit Passwort aus, es geht nur noch mit Schlüssel (kein Passwort-Erraten möglich). `disable_root: true` verbietet den direkten SSH-Login als `root`. Admin-Befehle laufen nur über einen normalen Benutzer mit `sudo`.
3. **`package_update: true`:** Beim ersten Boot wird der Paketindex aktualisiert (`apt-get update`), damit die Pakete unter `packages` in der aktuellen Version gefunden und installiert werden können.

**Reflexion:** Meine cloud-init-Datei aus KN01 lief lokal in Multipass und, nur um meinen öffentlichen Schlüssel erweitert, auch in AWS. Das funktioniert, weil beide Umgebungen ein Ubuntu-Cloud-Image mit cloud-init starten und cloud-init dieselbe deklarative Konfiguration beim ersten Boot gleich verarbeitet, egal ob sie von Multipass oder aus dem AWS-Feld «User data» kommt. Genau das ist eine Kerneigenschaft von Infrastructure as Code: Die Konfiguration liegt als Datei im Repository, ist versioniert und erzeugt bei jeder Ausführung reproduzierbar dasselbe Ergebnis. Bei GUI-Klicks gibt es dagegen keine Datei, die man übertragen könnte: Jeder Schritt muss in jeder Oberfläche von Hand wiederholt werden, ist nirgends festgehalten und kann jedes Mal etwas anders ausfallen. Universell ist die Datei aber nicht: Sie setzt ein Image mit cloud-init voraus und kann scheitern, wenn Paketnamen oder Pfade auf einem anderen System anders sind.

## Lernziele

- [x] Ich komme mit dem AWS Academy Learner Lab zurecht: Umgebung starten/stoppen, Budget einsehen, und ich weiss, was nach 4 Stunden passiert.
- [x] Ich kann eine EC2-Instanz erstellen und die Einstellungen zu Speicher, RAM und CPU bestimmen.
- [x] Ich kann erklären, wie die Public/Private-Key-Authentifizierung funktioniert und wo (Gerät und Verzeichnis) welcher Schlüssel liegen muss.
- [x] Ich kann den öffentlichen Schlüssel aus dem privaten extrahieren und den ssh-Befehl mit seinen Parametern anwenden.
- [x] Ich kann SSH-Schlüssel per cloud-init verteilen und habe mein persönliches cloud-init-Template erstellt (inkl. Schlüssel der Lehrperson).
- [x] Ich kann begründen, warum dieselbe cloud-init-Datei lokal (Multipass) und in AWS funktioniert – und was das über Infrastructure as Code aussagt.
