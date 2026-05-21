# FRE2026 FloriBot 4.0 Docker

Containerisierte Umgebung für den FloriBot 4.0. Die Hauptkomponenten basieren auf ROS 2 Jazzy. Die Objekterkennung verwendet aktuell einen separaten ROS-2-Humble-Container.

---

## Überblick

Dieses Repository stellt eine modulare Docker-Infrastruktur für den FloriBot 4.0 bereit.

**Features:**

- Trennung in hardwarenahe Komponenten und Simulation
- Unterstützung für:
  - Base (Kinematik + Robotik-Grundsystem)
  - Sensors (Sensorintegration)
  - Mapping (Kartierung und Lokalisierung)
  - Webteleop (Webbasierte Steuerung)
  - Stage (2D-Simulation)
  - Gazebo (3D-Simulation)
  - Tasks (Lösung der Aufgaben fürs FRE 2026)
  - Object Detection (Objekterkennung)
  - RViz (Visualisierung und Debugging)
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
├── mapping/<br/>
├── object_detection/<br/>
├── rviz/<br/>
├── compose/<br/>
├── scripts/<br/>
└── README.md<br/>


---
## Voraussetzungen
Betriebssystem: Linux (getestet mit Ubuntu-basierten Distributionen)<br/>
Docker Engine: ≥ 24.x<br/>
Docker Compose (Plugin v2): ≥ 2.x<br/>

Zusätzliche Voraussetzungen für GUI-/GPU-Container:

- X11-fähige Linux-Umgebung für Gazebo, Stage und RViz
- NVIDIA-GPU und NVIDIA Container Toolkit für `floribot-gazebo` und `floribot-object-detection`
- Zugriff auf `/dev`, USB und udev für Sensor- und Hardwarecontainer

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

### 3. X11-Freigabe für GUI (Gazebo, Stage und RViz)
Damit grafische Anwendungen aus dem Container angezeigt werden können
(z. B. Gazebo oder Stage), muss der lokale X-Server für Docker freigegeben werden:
```bash
xhost +local:docker
```
### 4. Konfiguration
Die Datei `compose/.env.example` enthält Beispielwerte. Für die lokale Ausführung muss daraus eine eigene `.env` erzeugt werden.<br/>
Konfigurationsdatei kopieren und eigene .env‑Datei erstellen:
```bash
cp compose/.env.example compose/.env
```
#### Netzwerk-Schnittstelle (CycloneDDS) wechseln

#### Konfigurationsparameter (Nur notwendig bei Containern auf verschiedenen Geräten im selben Netzwerk)
Um schnell zwischen verschiedenen Netzwerk-Konfigurationen (z. B. Ethernet eth0 oder WLAN wlp9s0) zu wechseln, kann die Variable CYCLONEDDS_CONFIG direkt in der .env überschrieben werden:
```bash
# Beispiel: Dauerhaft auf WLAN (wlp9s0) umstellen (Für PC mit WLAN-Verbindung)
sed -i 's/CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=wlp9s0/' compose/.env

# Beispiel: Dauerhaft auf Ethernet (eth0) umstellen (Für NVIDIA Jetson)
sed -i 's/CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=eth0/' compose/.env
```

| Variable | Bedeutung |
|---|---|
| `ROS_DOMAIN_ID` | ROS-2-Domain-ID zur Trennung mehrerer ROS-Netze |
| `ROS_AUTOMATIC_DISCOVERY_RANGE` | Discovery-Bereich für ROS-2-Teilnehmer |
| `RMW_IMPLEMENTATION` | Verwendete ROS-2-Middleware |
| `DISPLAY` | X11-Display für GUI-Anwendungen |
| `WAYLAND_DISPLAY` | Wayland-Display, relevant für WSLg/Wayland |
| `XDG_RUNTIME_DIR` | Runtime-Verzeichnis für Wayland/WSLg |
| `SICK_LAUNCH_FILE` | Launch-Datei für SICK-LiDAR |
| `SICK_FRONT_IP` | IP-Adresse des vorderen SICK-Sensors |
| `SICK_REAR_IP` | IP-Adresse des hinteren SICK-Sensors |
| `SICK_FRONT_FRAME` | TF-Frame des vorderen SICK-Sensors |
| `SICK_REAR_FRAME` | TF-Frame des hinteren SICK-Sensors |
| `RS_FRONT_SERIAL` | Seriennummer der vorderen Intel RealSense |
| `RS_REAR_SERIAL` | Seriennummer der hinteren Intel RealSense |
| `XSENS_ENABLE` | Aktiviert/deaktiviert XSens-Integration |
| `XSENS_SCAN_FOR_DEVICES` | Automatische Suche nach XSens-Geräten |
| `XSENS_PORT` | Serieller Port des XSens-Sensors |
| `XSENS_BAUDRATE` | Baudrate der XSens-Verbindung |
| `XSENS_FRAME_ID` | TF-Frame des XSens-Sensors |
| `XSENS_NAMESPACE` | ROS-Namespace für XSens-Daten |
| `XSENS_LOG_LEVEL` | Log-Level des XSens-Treibers |


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
| `floribot-mapping` | Mapping-Stack für Simulation und realen Roboter |
| `floribot-object-detection` | Objekterkennung mit NVIDIA/CUDA auf Basis von ROS 2 Humble |
| `floribot-rviz`          | RViz-Visualisierung                               |

#### Services bauen:
```bash
cd compose
docker compose build <Service>
```
Build ohne Cache (z. B. nach Änderungen im Dockerfile oder bei aktualisierten Abhängigkeiten im Repository):
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
| Profil | Startet Services | Beschreibung |
|---|---|---|
| `robot` | `floribot-base`, `floribot-sensors`, `floribot-mapping`, `floribot-tasks`, `floribot-object-detection` | Komplettes Robotik-System |
| `base` | `floribot-base` | Nur Robotik-Kern |
| `sensors` | `floribot-sensors` | Nur Sensorintegration |
| `stage` | `floribot-stage`, `floribot-mapping`, `floribot-tasks` | 2D-Simulation mit Stage |
| `sim` | `floribot-base-sim`, `floribot-gazebo`, `floribot-sim-backend`, `floribot-mapping`, `floribot-tasks` | 3D-Simulation mit Gazebo |
| `tasks` | `floribot-tasks` | Nur FRE-Tasks |
| `mapping` | `floribot-mapping` | Nur Mapping |
| `ui` | `floribot-base`, `floribot-webteleop` | Robotik-Kern und Web-Fernsteuerung |
| `webteleop` | `floribot-webteleop` | Nur Web-Fernsteuerung |
| `object-detection` | `floribot-object-detection` | Nur Objekterkennung |
| `rviz` | `floribot-rviz` | Nur RViz-Visualisierung |

#### Einzelne Profile starten am Beispiel von Profil `robot`:
```bash
cd compose
docker compose --profile robot up
```
#### Mehrere Profile kombinieren am Beispiel von Profil `robot` und `sim`:
```bash
cd compose
docker compose --profile robot --profile sim up
```
#### Hintergrundbetrieb am Beispiel von Profil `robot`:
```bash
cd compose
docker compose --profile robot up -d
```
#### Service-Konsole:
```bash
docker exec -it <Service> bash
```

#### Stoppen von Containern:
```bash
cd compose
docker compose down
```
Alternativ:
```bash
cd compose
docker compose stop <Service>
```

### 7. Tasks starten

Der Navigations-Task wird über den ROS-2-Service `/start_navigation` gestartet. Der Service-Call kann aus jedem laufenden Container dieses Repositories ausgeführt werden.

```bash
docker exec -it <Service> bash
ros2 service call /start_navigation std_srvs/srv/Trigger "{}"
```

Beispiel:

```bash
docker exec -it floribot-tasks bash
ros2 service call /start_navigation std_srvs/srv/Trigger "{}"
```
