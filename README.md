# FRE2026 FloriBot 4.0 Docker

Containerisierte ROS-2-Umgebung für den FloriBot 4.0 im Kontext des Field Robot Event 2026.

Das Repository bündelt die Docker-Images, Compose-Konfigurationen und Startskripte für reale Roboterhardware, Simulation, Mapping, Aufgabenlogik, Websteuerung, Visualisierung und ausgewählte Sensorsysteme.

---

## Inhalt

- [Überblick](#überblick)
- [Repository-Struktur](#repository-struktur)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Konfiguration](#konfiguration)
- [Services](#services)
- [Profile](#profile)
- [Build und Start](#build-und-start)
- [Typische Startvarianten](#typische-startvarianten)
- [ROS-2-Kommunikation und CycloneDDS](#ros-2-kommunikation-und-cyclonedds)
- [Sensor- und Hardwarekonfiguration](#sensor--und-hardwarekonfiguration)
- [Simulation](#simulation)
- [Mapping und Tasks](#mapping-und-tasks)
- [Webteleop und cmd_vel-Weiche](#webteleop-und-cmd_vel-weiche)
- [RViz](#rviz)
- [Debugging](#debugging)
- [Hinweise](#hinweise)

---

## Überblick

Dieses Repository stellt eine modulare Docker-Infrastruktur für den FloriBot 4.0 bereit.

Die meisten Container basieren auf **ROS 2 Jazzy**. Die Objekterkennung läuft aktuell separat auf Basis von **ROS 2 Humble** in einem Jetson-/CUDA-orientierten Container.

### Hauptkomponenten

| Komponente | Zweck |
|---|---|
| `base` | Robotik-Kern, Robot Description, PLC-Anbindung, Lokalisierung |
| `sensors` | SICK-LiDAR, Intel RealSense, Xsens MTi |
| `pantilt` | Pan-Tilt-Unit / FLIR PTU |
| `robosense` | RoboSense-LiDAR und Ground Segmentation |
| `webteleop` | Browserbasierte Teleoperation, Fahrquellenauswahl und sichere Weiterleitung von Geschwindigkeitsbefehlen über `cmd_vel_selector` |
| `stage` | 2D-Simulation mit Stage |
| `gazebo` | 3D-Simulation mit Gazebo / Gazebo Harmonic über ROS-GZ |
| `mapping` | Laser-Scan-Merger und SLAM Toolbox |
| `tasks` | FRE2026-Aufgabenlogik, insbesondere Maize Navigation |
| `object_detection` | YOLO-basierte Objekterkennung auf Jetson/CUDA |
| `rviz` | RViz-Konfiguration zur Visualisierung und Diagnose |

---

## Repository-Struktur

```text
FRE2026_FloriBot4.0_Docker/
├── base/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_base.sh
├── sensors/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── start_sensors.sh
│   ├── launch_lasers/
│   ├── launch_imu/
│   └── config_imu/
├── pantilt/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_pantilt.sh
├── robosense/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_robosense.sh
├── webteleop/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_webteleop.sh
├── stage/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── maize_world/
├── gazebo/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── ros2_ws/
│       └── src/
│           ├── floribot_gz_bringup/
│           ├── floribot_gz_description/
│           └── sim_backend/
├── mapping/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_mapping.sh
├── tasks/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_tasks.sh
├── object_detection/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── start_object_detection.sh
├── rviz/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── rviz/
│       └── floribot.rviz
├── compose/
│   ├── docker-compose.yml
│   ├── .env
│   ├── enp11s0_cyclonedds.xml
│   ├── eth0_cyclonedds.xml
│   └── wlp9s0_cyclonedds.xml
├── scripts/
│   ├── build.sh
│   ├── up.sh
│   ├── down.sh
│   └── logs.sh
├── .dockerignore
├── .gitignore
└── README.md
```

---

## Voraussetzungen

### Betriebssystem

Empfohlen wird ein Linux-System, z. B. Ubuntu oder eine Ubuntu-basierte Distribution.

Für GUI-Anwendungen wie Gazebo, Stage und RViz wird eine X11-fähige Umgebung benötigt.

### Docker

Benötigt werden:

```text
Docker Engine >= 24.x
Docker Compose Plugin v2
```

Prüfen:

```bash
docker --version
docker compose version
```

### NVIDIA / Jetson

Für folgende Container ist NVIDIA-Unterstützung relevant:

| Container | Voraussetzung |
|---|---|
| `floribot-object-detection` | NVIDIA Jetson / L4T R35, CUDA, NVIDIA Runtime |
| `floribot-gazebo` | NVIDIA-GPU empfohlen, NVIDIA Container Toolkit für GPU-Beschleunigung |

Der Object-Detection-Container basiert standardmäßig auf:

```text
dustynv/ros:humble-pytorch-l4t-r35.3.1
```

und ist auf ARM64/Jetson ausgelegt.

---

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/Team-FloriBot/FRE2026_FloriBot4.0_Docker.git
cd FRE2026_FloriBot4.0_Docker
```

### 2. Docker ohne `sudo` verwenden

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

### 3. X11 für Docker freigeben

Für Gazebo, Stage und RViz:

```bash
xhost +local:docker
```

Bei Problemen mit X11:

```bash
echo "$DISPLAY"
ls /tmp/.X11-unix
```

---

## Konfiguration

Die zentrale Konfigurationsdatei ist:

```text
compose/.env
```

Diese Datei wird von Docker Compose automatisch geladen.

Aktuelle Standardwerte:

```env
ROS_DOMAIN_ID=42
ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
DISPLAY=:0
WAYLAND_DISPLAY=wayland-0
XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir

SICK_LAUNCH_FILE=sick_tim_5xx.launch.py
SICK_FRONT_IP=192.168.0.52
SICK_REAR_IP=192.168.0.51
SICK_FRONT_FRAME=sick_front_link
SICK_REAR_FRAME=sick_rear_link

RS_FRONT_SERIAL=947522071563
RS_REAR_SERIAL=

CYCLONEDDS_CONFIG=enp11s0
CYCLONEDDS_URI=file:///etc/cyclonedds/cyclonedds.xml

ROBOT_LOCALIZATION_SHA=3efa714fb9c1ff40966327b7bed7053b2570be4d
LOCALIZATION_CONFIG=/ws/config/localization/local_ekf.yaml
```

---

## Wichtige Umgebungsvariablen

### ROS 2

| Variable | Bedeutung |
|---|---|
| `ROS_DOMAIN_ID` | ROS-2-Domain-ID zur Trennung verschiedener ROS-Netze |
| `ROS_AUTOMATIC_DISCOVERY_RANGE` | Discovery-Bereich für ROS-2-Kommunikation |
| `RMW_IMPLEMENTATION` | Verwendete Middleware, aktuell `rmw_cyclonedds_cpp` |
| `CYCLONEDDS_CONFIG` | Name der zu verwendenden CycloneDDS-Konfiguration |
| `CYCLONEDDS_URI` | Pfad zur CycloneDDS-Konfiguration im Container |

### GUI

| Variable | Bedeutung |
|---|---|
| `DISPLAY` | X11-Display für GUI-Anwendungen |
| `WAYLAND_DISPLAY` | Wayland-Display, relevant z. B. für WSLg |
| `XDG_RUNTIME_DIR` | Runtime-Verzeichnis für Wayland/WSLg |

### Lokalisierung

| Variable | Bedeutung |
|---|---|
| `ROBOT_LOCALIZATION_SHA` | Fester Commit für `robot_localization` |
| `LOCALIZATION_CONFIG` | Pfad zur EKF-Konfigurationsdatei im Container |

### SICK-LiDAR

| Variable | Bedeutung |
|---|---|
| `SICK_LAUNCH_FILE` | Launch-Datei für `sick_scan_xd` |
| `SICK_FRONT_IP` | IP-Adresse des vorderen SICK-LiDARs |
| `SICK_REAR_IP` | IP-Adresse des hinteren SICK-LiDARs |
| `SICK_FRONT_FRAME` | TF-Frame des vorderen SICK-LiDARs |
| `SICK_REAR_FRAME` | TF-Frame des hinteren SICK-LiDARs |

### Intel RealSense

| Variable | Bedeutung |
|---|---|
| `RS_FRONT_SERIAL` | Seriennummer der vorderen RealSense |
| `RS_REAR_SERIAL` | Seriennummer der hinteren RealSense |

Wenn eine Seriennummer leer ist, wird die jeweilige Kamera im Startskript nicht gestartet.

### Xsens MTi

| Variable | Bedeutung |
|---|---|
| `XSENS_ENABLE` | Aktiviert/deaktiviert Xsens |
| `XSENS_SCAN_FOR_DEVICES` | Automatische Suche nach Xsens-Geräten |
| `XSENS_PORT` | Serieller Port, z. B. `/dev/ttyUSB0` |
| `XSENS_BAUDRATE` | Baudrate |
| `XSENS_FRAME_ID` | TF-Frame |
| `XSENS_NAMESPACE` | ROS-Namespace |
| `XSENS_LOG_LEVEL` | Log-Level |

### Pan-Tilt

| Variable | Bedeutung |
|---|---|
| `PTU_PORT` | Serieller Port der Pan-Tilt-Unit |
| `PANTILT_LAUNCH_FILE` | Launch-Datei für Pan-Tilt |
| `PANTILT_DRIVER_ENABLE` | Aktiviert/deaktiviert Treiberlogik |

### RoboSense

| Variable | Bedeutung |
|---|---|
| `RSLIDAR_CONFIG` | Pfad zur RoboSense-Konfiguration |
| `GROUND_SEGMENTATION_CONFIG` | Pfad zur Ground-Segmentation-Konfiguration |
| `GROUND_SEGMENTATION_ENABLE` | Aktiviert/deaktiviert Ground Segmentation |

---

## Services

| Service | Profil(e) | Beschreibung |
|---|---:|---|
| `floribot-base` | `robot` | Robotik-Kern für den realen Roboter: Robot Description, Base Node, PLC, EKF |
| `floribot-base-sim` | `sim` | Base-Stack für die Gazebo-Simulation |
| `floribot-sensors` | `robot` | SICK-LiDAR, RealSense, Xsens |
| `floribot-pantilt` | `robot` | Pan-Tilt-Unit |
| `floribot-robosense` | `robot` | RoboSense-LiDAR und Ground Segmentation |
| `floribot-webteleop` | `robot`, `stage` | Webserver für browserbasierte Teleoperation sowie `cmd_vel_selector` als zentrale Fahrbefehlsweiche |
| `floribot-stage` | `stage` | 2D-Simulation mit Stage |
| `floribot-gazebo` | `sim` | Gazebo-Simulation mit Maize-World und FloriBot-Modell |
| `floribot-sim-backend` | `sim` | ROS-Gazebo-Bridge und Simulationsbackend |
| `floribot-mapping` | `sim`, `stage`, `laptop` | Laser Scan Merger und SLAM Toolbox |
| `floribot-tasks` | `sim`, `stage`, `laptop` | Maize Navigation und FRE2026-Tasks |
| `floribot-object-detection` | `robot` | YOLO-basierte Objekterkennung auf Jetson/CUDA |
| `floribot-rviz` | `rviz` | RViz mit vorkonfigurierter Ansicht |

---

## Profile

### `robot`

Startet die Container für das reale Robotersystem:

```text
floribot-base
floribot-sensors
floribot-pantilt
floribot-robosense
floribot-webteleop
floribot-object-detection
```

Start:

```bash
cd compose
docker compose --profile robot up
```

Hintergrundbetrieb:

```bash
cd compose
docker compose --profile robot up -d
```

---

### `sim`

Startet die Gazebo-basierte 3D-Simulation:

```text
floribot-base-sim
floribot-gazebo
floribot-sim-backend
floribot-mapping
floribot-tasks
```

Start:

```bash
cd compose
docker compose --profile sim up
```

---

### `stage`

Startet die Stage-basierte 2D-Simulation:

```text
floribot-webteleop
floribot-stage
floribot-mapping
floribot-tasks
```

Start:

```bash
cd compose
docker compose --profile stage up
```

---

### `laptop`

Startet nur Mapping und Tasks, z. B. zur Anbindung an ein externes ROS-Netz:

```text
floribot-mapping
floribot-tasks
```

Start:

```bash
cd compose
docker compose --profile laptop up
```

---

### `rviz`

Startet RViz:

```text
floribot-rviz
```

Start:

```bash
cd compose
docker compose --profile rviz up
```

---

## Build und Start

### Alle Services bauen

```bash
cd compose
docker compose build
```

oder über Skript:

```bash
./scripts/build.sh
```

### Einzelnen Service bauen

```bash
cd compose
docker compose build floribot-base
```

### Ohne Cache bauen

```bash
cd compose
docker compose build --no-cache floribot-base
```

### Profil bauen

```bash
cd compose
docker compose --profile robot build
```

### Profil starten

```bash
cd compose
docker compose --profile robot up
```

### Im Hintergrund starten

```bash
cd compose
docker compose --profile robot up -d
```

### Alle gestarteten Container stoppen

```bash
cd compose
docker compose down
```

oder:

```bash
./scripts/down.sh
```

### Logs anzeigen

```bash
cd compose
docker compose logs -f
```

oder:

```bash
./scripts/logs.sh
```

### Shell in Container öffnen

```bash
docker exec -it floribot-base bash
```

Beispiele:

```bash
docker exec -it floribot-sensors bash
docker exec -it floribot-mapping bash
docker exec -it floribot-tasks bash
docker exec -it floribot-rviz bash
```

---

## Typische Startvarianten

### Reales Robotersystem

```bash
cd compose
docker compose --profile robot up
```

Mit RViz zusätzlich:

```bash
cd compose
docker compose --profile robot --profile rviz up
```

### Gazebo-Simulation mit Mapping und Tasks

```bash
cd compose
docker compose --profile sim up
```

Mit RViz zusätzlich:

```bash
cd compose
docker compose --profile sim --profile rviz up
```

### Stage-Simulation mit Mapping, Tasks und Webteleop

```bash
cd compose
docker compose --profile stage up
```

### Nur Mapping und Tasks auf Laptop

```bash
cd compose
docker compose --profile laptop up
```

### Nur RViz

```bash
cd compose
docker compose --profile rviz up
```

---

## ROS-2-Kommunikation und CycloneDDS

Die Container verwenden Host-Networking und CycloneDDS.

In `compose/.env` wird über folgende Variable ausgewählt, welche CycloneDDS-Konfiguration eingebunden wird:

```env
CYCLONEDDS_CONFIG=enp11s0
```

Damit wird im Compose-File z. B. folgende Datei in den Container gemountet:

```text
compose/enp11s0_cyclonedds.xml
```

Verfügbare Konfigurationen:

```text
compose/enp11s0_cyclonedds.xml
compose/eth0_cyclonedds.xml
compose/wlp9s0_cyclonedds.xml
```

### Netzwerkschnittstelle ermitteln

```bash
ip route
```

Typische Schnittstellen:

| Schnittstelle | Typischer Einsatz |
|---|---|
| `enp11s0` | Ethernet auf Laptop/PC |
| `eth0` | Ethernet auf Jetson |
| `wlp9s0` | WLAN |

### CycloneDDS-Konfiguration wechseln

Ethernet-PC:

```bash
sed -i 's/^CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=enp11s0/' compose/.env
```

Jetson:

```bash
sed -i 's/^CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=eth0/' compose/.env
```

WLAN-PC:

```bash
sed -i 's/^CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=wlp9s0/' compose/.env
```

Raspberry PI:

```bash
sed -i 's/^CYCLONEDDS_CONFIG=.*/CYCLONEDDS_CONFIG=eth0pi/' compose/.env
```
---

## Sensor- und Hardwarekonfiguration

### SICK-LiDAR

Der Sensorcontainer startet `sick_scan_xd` über:

```bash
ros2 launch sick_scan_xd laser.launch.py
```

Die Launch-Konfiguration wird aus `sensors/launch_lasers/` in den Container kopiert.

Konfiguration in `compose/.env`:

```env
SICK_FRONT_IP=192.168.0.52
SICK_REAR_IP=192.168.0.51
SICK_FRONT_FRAME=sick_front_link
SICK_REAR_FRAME=sick_rear_link
```

### Intel RealSense

Die RealSense-Kameras werden nur gestartet, wenn die jeweilige Seriennummer gesetzt ist.

```env
RS_FRONT_SERIAL=947522071563
RS_REAR_SERIAL=
```

Bei leerem `RS_REAR_SERIAL` wird die hintere Kamera deaktiviert.

Im Container werden die Topics unter dem Namespace `sensors` gestartet, z. B.:

```text
/sensors/realsense_front/...
/sensors/realsense_rear/...
```

### Xsens MTi

Aktivierung über:

```env
XSENS_ENABLE=true
```

Start im Sensorcontainer:

```bash
ros2 launch xsens_mti_ros2_driver imu.launch.py xsens_namespace:=/sensors/xsens
```

### Pan-Tilt

Der Container `floribot-pantilt` startet standardmäßig:

```bash
ros2 launch aim_and_fire aim_and_fire.launch.py
```

Wichtige Variablen:

```env
PTU_PORT=/dev/ttyUSB0
PANTILT_LAUNCH_FILE=aim_and_fire.launch.py
PANTILT_DRIVER_ENABLE=true
```

Wenn `PTU_PORT` im Container nicht existiert, gibt das Startskript eine Warnung aus.

### RoboSense

Der Container `floribot-robosense` startet:

```text
rslidar_sdk_node
ground_segmentation_node
```

Die TF-Ausgabe des RoboSense-Stacks wird bewusst auf eigene blockierte Topics remapped:

```text
/robosense/blocked_tf
/robosense/blocked_tf_static
```

Damit trägt RoboSense nicht direkt zum globalen TF-Baum des Roboters bei.

---

## Simulation

### Stage

Der Stage-Container startet:

```bash
ros2 launch stage_ros2 stage.launch.py world:=maize_field enforce_prefixes:=false one_tf_tree:=false frame_id_base_link:=base_link
```

Zusätzlich werden die Stage-Laserscan-Topics gerelayed:

```text
/base_scan1 -> /sensors/scan_front
/base_scan2 -> /sensors/scan_rear
```

Die Stage-World liegt unter:

```text
stage/maize_world/
```

### Gazebo

Der Gazebo-Container enthält:

```text
gazebo/ros2_ws/src/floribot_gz_description
gazebo/ros2_ws/src/floribot_gz_bringup
gazebo/ros2_ws/src/sim_backend
```

Standardstart:

```bash
ros2 launch floribot_gz_bringup maize_world_with_floribot.launch.py
```

Das Simulationsbackend startet zusätzlich eine ROS-Gazebo-Bridge für:

```text
/sim/joint_frontLeft/cmd_vel
/sim/joint_frontRight/cmd_vel
/sim/joint_rearLeft/cmd_vel
/sim/joint_rearRight/cmd_vel
/sensors/scan_front
/sensors/scan_rear
/sensors/realsense_front/color/image_raw
/sensors/realsense_rear/color/image_raw
```

Danach wird gestartet:

```bash
ros2 run sim_backend sim_backend_node
```

---

## Mapping und Tasks

### Mapping

Der Mapping-Container startet:

```text
laser_scan_merger
slam_toolbox
```

Startskript:

```bash
/start_mapping.sh
```

Intern:

```bash
ros2 launch laser_scan_merger start.launch.py robotname:=floribot_config
ros2 launch slam_toolbox online_sync_launch.py \
  slam_params_file:=/ws/src/FRE2026_Tasks/src/slam_toolbox/config/mapper_params_online_sync.yaml
```

### Tasks

Der Task-Container startet die Maize Navigation:

```bash
ros2 launch maize_navigation maize_navigation.launch.py
```

Startskript:

```bash
/start_tasks.sh
```

### Navigation manuell starten

Der Navigations-Task kann über den ROS-2-Service `/start_navigation` gestartet werden:

```bash
docker exec -it floribot-tasks bash
ros2 service call /start_navigation std_srvs/srv/Trigger "{}"
```

Einzeiler:

```bash
docker exec -it floribot-tasks bash -lc 'ros2 service call /start_navigation std_srvs/srv/Trigger "{}"'
```

---

## Object Detection

Der Container `floribot-object-detection` basiert auf ROS 2 Humble und ist für Jetson/L4T ausgelegt.

Standard-Base-Image:

```text
dustynv/ros:humble-pytorch-l4t-r35.3.1
```

Der Container baut bzw. enthält:

```text
cv_bridge
realsense2_camera_msgs
CycloneDDS
rmw_cyclonedds_cpp
ros2_detection_interfaces
ros2_detection
YOLO/Ultralytics-Abhängigkeiten
pyrealsense2
```

Startskript:

```bash
/start_object_detection.sh
```

Vor dem Start wird geprüft:

```text
CUDA verfügbar
OpenMP/scikit-learn importierbar
pyrealsense2 importierbar
```

Danach startet:

```bash
ros2 launch ros2_detection detector.launch.py
```

---

## Webteleop und `cmd_vel`-Weiche

Der Container `floribot-webteleop` stellt zwei Funktionen bereit:

1. eine browserbasierte Bedienoberfläche für manuelle Fahrbefehle und Task-Bedienung,
2. eine zentrale `cmd_vel`-Weiche zur Auswahl genau einer aktiven Fahrbefehlsquelle.

Damit werden manuelle Bedienung, autonome Task-Navigation und weitere Bewegungsquellen nicht parallel auf den Antrieb durchgeschaltet. Stattdessen entscheidet der `cmd_vel_selector`, welche Quelle den globalen Fahrbefehl auf `/cmd_vel` ausgeben darf.

### Start im Docker-Container

Der Container startet über:

```bash
/start_webteleop.sh
```

Das Startskript startet intern zwei ROS-2-Komponenten:

```bash
ros2 launch cmd_vel_selector cmd_vel_selector.launch.py
ros2 run web_teleop web_teleop_server
```

Der Service ist in den Compose-Profilen `robot` und `stage` enthalten.

### Systemprinzip

```text
Browser
  │  HTTP / WebSocket
  ▼
web_teleop_server
  │
  ├── publiziert manuelle Fahrbefehle ─────► /cmd_vel/webteleop
  │
  ├── wählt aktive Quelle ─────────────────► /cmd_vel_selector/select_source
  │◄─ liest aktive Quelle ────────────────── /cmd_vel_selector/active_source
  │
  ├── bedient Task-1-Services ─────────────► /set_navigation_pattern
  ├────────────────────────────────────────► /start_navigation
  ├────────────────────────────────────────► /pause_navigation
  ├────────────────────────────────────────► /resume_navigation
  └────────────────────────────────────────► /stop_navigation

cmd_vel_selector
  ├── liest /cmd_vel/webteleop
  ├── liest /cmd_vel/task1
  ├── liest /cmd_vel/task2
  ├── liest /cmd_vel/task3
  ├── liest /cmd_vel/task4
  ├── liest /cmd_vel/task5
  └── publiziert genau die aktive Quelle ──► /cmd_vel
```

### Webteleop

`web_teleop_server` ist ein ROS-2-Node mit integriertem FastAPI-/Uvicorn-Webserver. Die Bedienoberfläche wird über HTTP ausgeliefert, die Steuerdaten werden über WebSocket übertragen.

Standardmäßig ist die Oberfläche über Port `8000` erreichbar:

```text
http://localhost:8000
```

Bei Zugriff aus dem selben Netzwerk, z. B. von einem Smartphone oder Tablet:

```text
http://<IP-DES-ROBOTERS>:8000
```

Die Webteleop erzeugt Geschwindigkeitsbefehle vom Typ `geometry_msgs/msg/Twist` und publiziert diese standardmäßig mit 20 Hz auf:

```text
/cmd_vel/webteleop
```

Dabei gelten folgende Schutzmechanismen:

| Mechanismus | Funktion |
|---|---|
| Backend-Begrenzung | Begrenzung von `linear.x` und `angular.z` auf parametrierbare Maximalwerte |
| Deadman-Timeout | Ausgabe von `v = 0` und `ω = 0`, wenn keine aktuellen Web-Befehle empfangen werden |
| Stopp beim Quellenwechsel | Vor dem Umschalten der aktiven Quelle wird ein Nullbefehl publiziert |
| Stopp bei Verbindungsverlust | Bei WebSocket-Abbruch wird die zuletzt angeforderte Bewegung zurückgesetzt |

Wichtige Parameter des Webteleop-Nodes:

| Parameter | Standardwert | Einheit | Bedeutung |
|---|---:|---|---|
| `cmd_vel_topic` | `/cmd_vel/webteleop` | – | Topic für manuelle Fahrbefehle |
| `max_linear` | `1.0` | m/s | Obergrenze für `linear.x` |
| `max_angular` | `0.9` | rad/s | Obergrenze für `angular.z` |
| `timeout_s` | `0.3` | s | Deadman-Zeit ohne neue WebSocket-Befehle |

### `cmd_vel_selector`

Der `cmd_vel_selector` ist die zentrale Fahrbefehlsweiche des Systems. Er abonniert mehrere mögliche Eingangsquellen und veröffentlicht nur die aktuell ausgewählte Quelle auf das globale Ausgangstopic.

Standard-Ausgang:

```text
/cmd_vel
```

Konfigurierte Eingangstopics:

| Quelle | Eingangstopic | Typische Verwendung |
|---|---|---|
| `webteleop` | `/cmd_vel/webteleop` | manuelle Bedienung über Weboberfläche |
| `task1` | `/cmd_vel/task1` | autonome Navigation für Task 1 |
| `task2` | `/cmd_vel/task2` | reserviert für Task 2 |
| `task3` | `/cmd_vel/task3` | reserviert für Task 3 |
| `task4` | `/cmd_vel/task4` | reserviert für Task 4 |
| `task5` | `/cmd_vel/task5` | reserviert für Task 5 |
| `none` | – | keine Quelle aktiv; der Roboter erhält einen Stoppbefehl |

Die Auswahl erfolgt über den Service:

```text
/cmd_vel_selector/select_source
```

Der aktuell aktive Zustand wird auf folgendem Topic publiziert:

```text
/cmd_vel_selector/active_source
```

Dieses Status-Topic verwendet eine latched-artige QoS-Konfiguration mit `RELIABLE` und `TRANSIENT_LOCAL`, sodass neu gestartete Teilnehmer den zuletzt bekannten Quellenstatus erhalten können.

Zusätzlich existiert ein Stop-Service:

```text
/cmd_vel_selector/stop
```

Dieser setzt die aktive Quelle auf `none` und publiziert einen Nullbefehl auf `/cmd_vel`.

### Manuelle Bedienung über Webteleop

1. `robot`- oder `stage`-Profil starten.
2. Browser öffnen: `http://<IP-DES-ROBOTERS>:8000`.
3. Als Fahrquelle `Webteleop` auswählen.
4. Gewünschte Maximalgeschwindigkeiten in der Oberfläche begrenzen.
5. Roboter über den virtuellen Joystick bewegen.
6. Beim Loslassen oder Verbindungsverlust wird ein Stoppbefehl ausgegeben.

### Task-Bedienung über Webteleop

Die Oberfläche kann zusätzlich die Task-1-Navigation bedienen. Dafür wird die Quelle `task1` über den `cmd_vel_selector` aktiviert. Anschließend können Fahrmuster gesetzt sowie Navigation gestartet, pausiert, fortgesetzt und gestoppt werden.

Relevante Services:

| Service | Funktion |
|---|---|
| `/set_navigation_pattern` | Fahrmuster setzen, z. B. `1L 2R` |
| `/get_navigation_status` | aktuellen Navigationszustand abfragen |
| `/start_navigation` | Navigation starten |
| `/pause_navigation` | Navigation pausieren |
| `/resume_navigation` | Navigation fortsetzen |
| `/stop_navigation` | Navigation stoppen |

### Manuelle Service-Aufrufe

Aktive Quelle auf Webteleop setzen:

```bash
ros2 service call /cmd_vel_selector/select_source cmd_vel_selector/srv/SelectSource "{source: 'webteleop'}"
```

Aktive Quelle auf Task 1 setzen:

```bash
ros2 service call /cmd_vel_selector/select_source cmd_vel_selector/srv/SelectSource "{source: 'task1'}"
```

Fahrbefehle sperren und Stoppbefehl ausgeben:

```bash
ros2 service call /cmd_vel_selector/stop std_srvs/srv/Trigger "{}"
```

---

## RViz

RViz wird über das Profil `rviz` gestartet:

```bash
cd compose
docker compose --profile rviz up
```

Die verwendete RViz-Konfiguration liegt unter:

```text
rviz/rviz/floribot.rviz
```

Der Container startet standardmäßig:

```bash
rviz2 -d /ws/src/rviz/floribot.rviz
```

---

## Debugging

### Laufende Container anzeigen

```bash
docker ps
```

### Logs eines Containers anzeigen

```bash
docker logs -f floribot-base
```

oder über Compose:

```bash
cd compose
docker compose logs -f floribot-base
```

### ROS-Topics prüfen

```bash
docker exec -it floribot-base bash
ros2 topic list
```

### ROS-Nodes prüfen

```bash
docker exec -it floribot-base bash
ros2 node list
```

### Aktive Fahrquelle prüfen

```bash
docker exec -it floribot-webteleop bash -lc 'ros2 topic echo /cmd_vel_selector/active_source --once'
```

### Aktive Fahrquelle stoppen

```bash
docker exec -it floribot-webteleop bash -lc 'ros2 service call /cmd_vel_selector/stop std_srvs/srv/Trigger "{}"'
```

### TF prüfen

```bash
docker exec -it floribot-rviz bash
ros2 run tf2_tools view_frames
```

### ROS-Domain prüfen

```bash
docker exec -it floribot-base bash -lc 'echo $ROS_DOMAIN_ID'
```

### Middleware prüfen

```bash
docker exec -it floribot-base bash -lc 'echo $RMW_IMPLEMENTATION'
```

### CycloneDDS-Konfiguration im Container prüfen

```bash
docker exec -it floribot-base bash -lc 'cat /etc/cyclonedds/cyclonedds.xml'
```

### Container neu bauen

```bash
cd compose
docker compose build --no-cache floribot-base
```

### Alle Container und Netzwerke stoppen

```bash
cd compose
docker compose down
```

---

## Skripte

Die Skripte im Verzeichnis `scripts/` sind einfache Wrapper um Docker Compose:

| Skript | Funktion |
|---|---|
| `scripts/build.sh` | Führt `docker compose build` in `compose/` aus |
| `scripts/up.sh` | Führt `docker compose up -d` in `compose/` aus |
| `scripts/down.sh` | Führt `docker compose down` in `compose/` aus |
| `scripts/logs.sh` | Führt `docker compose logs -f` in `compose/` aus |

Beispiel:

```bash
./scripts/build.sh
./scripts/up.sh
./scripts/logs.sh
./scripts/down.sh
```

Hinweis: Die Skripte starten ohne explizite Profile. Für profilbasierte Starts wird empfohlen, direkt Docker Compose zu verwenden:

```bash
cd compose
docker compose --profile sim up
```

---

## Externe Repositories

Die Dockerfiles ziehen beim Build unter anderem folgende externe Repositories:

| Zweck | Repository |
|---|---|
| Base / Robot Description / PLC | `Team-FloriBot/FloriBot4.0_ROS2_Jazzy_Base` |
| FRE2026 Tasks | `Team-FloriBot/FRE2026_Tasks` |
| Webteleop | `Team-FloriBot/Webteleop_ROS2_Jazzy_V1` |
| Object Detection | `Team-FloriBot/FRE_object_detection` |
| SICK-LiDAR | `SICKAG/sick_scan_xd` |
| RealSense ROS | `realsenseai/realsense-ros` |
| librealsense | `IntelRealSense/librealsense` |
| Xsens MTi | `xsenssupport/Xsens_MTi_ROS_Driver_and_Ntrip_Client` |
| Stage | `tuw-robotics/Stage` |
| stage_ros2 | `tuw-robotics/stage_ros2` |
| Virtual Maize Field | `FieldRobotEvent/virtual_maize_field` |
| robot_localization | `cra-ros-pkg/robot_localization` |
| PanTilt | `Team-FloriBot/PANTILT_ROS2_Jazzy` |
| FLIR PTU Driver | `vicoslab/flir_ptu_driver` |
| RoboSense | `Team-FloriBot/FRE_RoboSenseAIRY` |

Einige Abhängigkeiten werden bewusst auf bestimmte Commits oder Branches gepinnt, um reproduzierbare Builds zu ermöglichen.

---

## Hinweise

- Die Hardwarecontainer verwenden `network_mode: host`, `ipc: host`, `pid: host` und teilweise `privileged: true`.
- Sensor- und Hardwarecontainer mounten `/dev`, `/dev/bus/usb` und `/run/udev`.
- `floribot-sensors`, `floribot-pantilt`, `floribot-robosense` und `floribot-object-detection` sind im Compose-File als `linux/arm64` bzw. Jetson-orientiert konfiguriert.
- `floribot-object-detection` verwendet ROS 2 Humble, während die übrigen Hauptcontainer auf ROS 2 Jazzy basieren.
- Die ROS-2-Kommunikation zwischen den Containern erfolgt über Host-Netzwerk und CycloneDDS.
- Für GUI-Container muss X11 korrekt freigegeben sein.
- Für GPU-Container muss das NVIDIA Container Toolkit bzw. die Jetson-NVIDIA-Runtime korrekt eingerichtet sein.
