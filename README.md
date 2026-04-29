# FRE2026 FloriBot 4.0 Docker

Containerisierte Umgebung für den FloriBot 4.0 auf Basis von ROS 2 Jazzy.

---

## Überblick

Dieses Repository stellt eine modulare Docker-Infrastruktur für den FloriBot 4.0 bereit.

**Features:**

- Trennung in hardwarenahe Komponenten und Simulation
- Unterstützung für:
  - Base (Kinematik + Robotik-Grundsystem)
  - Sensors (Sensorintegration)
  - Webteleop (Webbasierte Steuerung)
  - Stage (2D-Simulation)
  - Gazebo (3D-Simulation)
  - Tasks (Lösung der Aufgaben fürs FRE 2026)
- Docker Compose mit Profilen
- Skriptbasierte Steuerung (Build, Start, Stop, Logs)

---

## Repository-Struktur
FRE2026_FloriBot4.0_Docker/<br/>
├── base/<br/>
├── sensors/<br/>
├── webteleop/<br/>
├── stage/<br/>
├── gazebo/<br/>
├── tasks/<br/>
├── compose/<br/>
├── scripts/<br/>
└── README.md<br/>


---
## Voraussetzungen
Betriebssystem: Linux (getestet mit Ubuntu-basierten Distributionen)<br/>
Docker Engine: ≥ 24.x<br/>
Docker Compose (Plugin v2): ≥ 2.x<br/>

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/Team-FloriBot/FRE2026_FloriBot4.0_Docker.git
cd FRE2026_FloriBot4.0_Docker
```

### 2. Docker ohne sudo verwenden (Linux)
Damit Docker-Befehle ohne sudo ausgeführt werden können:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. X11-Freigabe für GUI (Gazebo)
Damit grafische Anwendungen aus dem Container angezeigt werden können
(z. B. Gazebo oder Stage), muss der lokale X-Server für Docker freigegeben werden:
```bash
xhost +local:docker
```
### 4. Konfiguration
Die Datei compose/.env enthält aktuell folgende Konfigurationsparameter:

```bash
ROS_DOMAIN_ID=42 # ROS-2-Domain-ID zur Trennung von Kommunikationsdomänen
```

```bash
ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET # Discovery-Bereich für ROS-2-Teilnehmer im Netzwerk
```

```bash
RMW_IMPLEMENTATION=rmw_fastrtps_cpp # Verwendete ROS-2-Middleware
```

```bash
DISPLAY=:0 # X11-Display für GUI-Anwendungen wie Gazebo oder Stage
```
Konfigurationsdatei kopieren und eigene .env‑Datei erstellen:
```bash
cp compose/.env.example compose/.env
```
### 5. Services bauen und starten
| Service                  | Beschreibung                                      |
| ------------------------ | ------------------------------------------------- |
| `floribot-base`          | Robotik-Kern + Kinematik für den realen Roboter   |
| `floribot-sensors`       | Sensorintegration für das reale System            |
| `floribot-webteleop`     | Webbasierte Steuerung für den Roboter             |
| `floribot-base-sim`      | Basis-Stack für die Simulation                    |
| `floribot-stage`         | 2D-Simulation mit Stage                           |
| `floribot-gazebo`        | 3D-Simulation mit Gazebo                          |
| `floribot-sim-backend`   | Simulations-Backend inkl. ROS–Gazebo-Bridge       |
| `floribot-tasks`         | Tasks fürs FRE 2026                               |

#### Services bauen:
```bash
cd compose
docker compose build <Service>
```
Bauen ohne Cache (z.B. nach Anpassungen im Dockerfile oder nach änderungen im Repo)
```bash
cd compose
docker compose build <Service> --no-cache
```
Alternativ:
```bash
cd compose
docker compose build <Service1> <Service2> <Service3>
```
#### Services starten:
```bash
cd compose
docker compose up <Service>
```
Alternativ:
```bash
cd compose
docker compose up <Service1> <Service2> <Service3>
```
### 6. Profile starten
| Profil    | Startet Services                                                                                           | Beschreibung                              |
| --------- | -----------------------------------------------------------------------------------------------------------| ----------------------------------------- |
| `robot`   | `floribot-base`, `floribot-sensors`, `floribot-tasks`                                                      | Komplettes Robotik-System                 |
| `base`    | `floribot-base`                                                                                            | Nur Robotik-Kern                          |
| `sensors` | `floribot-sensors`                                                                                         | Nur Sensorintegration                     |
| `stage`   | `floribot-stage`, `floribot-tasks`                                                                         | 2D-Simulation                             |
| `sim`     | `floribot-base-sim`, `floribot-webteleop-sim`, `floribot-gazebo`, `floribot-sim-backend`, `floribot-tasks` | 3D-Simulationsumgebung mit Backend        |
| `tasks`   | `floribot-tasks`                                                                                           | Nur Tasks fürs FRE 2026                       |

#### Einzelne Profile starten am Beispiel von Profil `robot`:
```bash
docker compose --profile robot up
```
#### Mehrere Profile kombinieren am Beispiel von Profil `robot` und `sim`:
```bash
docker compose --profile robot --profile sim up
```
#### Hintergrundbetrieb am Beispiel von Profil `robot`:
```bash
docker compose --profile robot up -d
```
#### Service-Konsole:
```bash
docker exec -it <Service> bash
```

#### Stoppen von Containern:
```bash
docker compose down
```
