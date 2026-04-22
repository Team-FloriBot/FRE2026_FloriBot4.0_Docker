# FRE2026 FloriBot 4.0 Docker

Containerisierte Umgebung für den FloriBot 4.0 auf Basis von ROS 2.

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
├── compose/<br/>
├── scripts/<br/>
└── README.md<br/>


---

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
Damit grafische Anwendungen aus dem Container angezeigt werden:
```bash
xhost +local:docker
```
### 4. Konfiguration

```bash
cp compose/.env.example compose/.env
```

Rest fehlt noch...
