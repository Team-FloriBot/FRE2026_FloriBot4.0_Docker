<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FRE2026 FloriBot 4.0 Docker – README</title>
  <style>
    :root {
      --bg: #f6f8fb;
      --card: #ffffff;
      --text: #1f2937;
      --muted: #4b5563;
      --line: #d1d5db;
      --accent: #0f766e;
      --accent-soft: #ecfeff;
      --code: #111827;
      --code-bg: #f3f4f6;
      --warn-bg: #fff7ed;
      --warn-border: #fdba74;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 32px;
      font-family: Arial, Helvetica, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
    }
    .container {
      max-width: 1100px;
      margin: 0 auto;
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 16px;
      padding: 40px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.06);
    }
    h1, h2, h3, h4 {
      color: #0f172a;
      margin-top: 1.4em;
      margin-bottom: 0.5em;
      line-height: 1.25;
    }
    h1 { margin-top: 0; font-size: 2rem; }
    h2 {
      border-bottom: 2px solid var(--line);
      padding-bottom: 8px;
      font-size: 1.45rem;
    }
    h3 { font-size: 1.15rem; }
    p { margin: 0.6em 0; }
    ul, ol { margin: 0.5em 0 1em 1.25em; }
    li { margin: 0.25em 0; }
    code {
      font-family: "Courier New", Courier, monospace;
      background: var(--code-bg);
      padding: 0.15em 0.35em;
      border-radius: 6px;
      color: var(--code);
    }
    pre {
      background: var(--code-bg);
      border: 1px solid var(--line);
      border-radius: 10px;
      padding: 14px 16px;
      overflow-x: auto;
      margin: 0.8em 0 1.1em;
    }
    pre code {
      background: transparent;
      padding: 0;
      border-radius: 0;
    }
    .note, .warning {
      border-left: 5px solid var(--accent);
      background: var(--accent-soft);
      padding: 14px 16px;
      border-radius: 10px;
      margin: 1em 0;
    }
    .warning {
      border-left-color: #ea580c;
      background: var(--warn-bg);
      border: 1px solid var(--warn-border);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 1em 0 1.2em;
    }
    th, td {
      border: 1px solid var(--line);
      padding: 10px 12px;
      text-align: left;
      vertical-align: top;
    }
    th {
      background: #f9fafb;
    }
    .muted { color: var(--muted); }
    .badge {
      display: inline-block;
      background: #ecfeff;
      color: #155e75;
      border: 1px solid #a5f3fc;
      border-radius: 999px;
      padding: 3px 10px;
      font-size: 0.9rem;
      margin-right: 6px;
      margin-bottom: 6px;
    }
  </style>
</head>
<body>
  <main class="container">
    <h1>FRE2026 FloriBot 4.0 Docker</h1>
    <p>Containerisierte Umgebung für den FloriBot&nbsp;4.0 auf Basis von ROS&nbsp;2.</p>

    <h2>Überblick</h2>
    <p>Dieses Repository stellt eine modulare Docker-Infrastruktur für den FloriBot&nbsp;4.0 bereit. Die Umgebung trennt reale Robotik-Komponenten von Simulationskomponenten und erlaubt den gezielten Start einzelner Teilsysteme über Docker-Compose-Profile.</p>

    <h3>Funktionen</h3>
    <ul>
      <li>Trennung zwischen hardwarenaher Laufzeit und Simulation</li>
      <li>Unterstützung für Base, Sensors, Webteleop, Stage und Gazebo</li>
      <li>Profilbasierter Start über Docker Compose</li>
      <li>Skriptbasierte Bedienung für Build, Start, Stop und Logs</li>
      <li>X11-Weitergabe für grafische Anwendungen unter Linux</li>
    </ul>

    <h2>Repository-Struktur</h2>
<pre><code>FRE2026_FloriBot4.0_Docker/
├── base/
├── sensors/
├── webteleop/
├── stage/
├── gazebo/
├── compose/
├── scripts/
└── README.md</code></pre>

    <h2>Voraussetzungen</h2>
    <ul>
      <li>Linux mit Docker Engine und Docker Compose Plugin</li>
      <li>Git</li>
      <li>X11-Server für grafische Anwendungen wie Stage oder Gazebo</li>
    </ul>

    <div class="warning">
      <strong>Hinweis:</strong> Die grafische Ausgabe von Stage und Gazebo ist auf Linux typischerweise nur verfügbar, wenn der Docker-Container Zugriff auf den lokalen X-Server erhält. Die dafür notwendigen Schritte sind im Abschnitt <em>Grafische Ausgabe unter Linux</em> beschrieben.
    </div>

    <h2>Installation</h2>

    <h3>1. Repository klonen</h3>
<pre><code>git clone https://github.com/Team-FloriBot/FRE2026_FloriBot4.0_Docker.git
cd FRE2026_FloriBot4.0_Docker</code></pre>

    <h3>2. Docker ohne dauerhaftes <code>sudo</code> verwenden</h3>
    <p>Unter Linux kann der eigene Benutzer zur Docker-Gruppe hinzugefügt werden, damit Docker-Kommandos ohne <code>sudo</code> ausgeführt werden können.</p>
<pre><code>sudo usermod -aG docker $USER</code></pre>
    <p>Danach ist eine neue Anmeldung erforderlich. Entweder ab- und wieder anmelden oder die Gruppenzugehörigkeit in der aktuellen Shell neu laden:</p>
<pre><code>newgrp docker</code></pre>

    <h3>3. Konfiguration anlegen</h3>
<pre><code>cp compose/.env.example compose/.env</code></pre>

    <p>Die Beispielkonfiguration enthält aktuell folgende Parameter:</p>
<pre><code>ROS_DOMAIN_ID=42
ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET
RMW_IMPLEMENTATION=rmw_fastrtps_cpp
DISPLAY=:0</code></pre>

    <h3>4. Images bauen</h3>
<pre><code>cd compose
docker compose build</code></pre>

    <p>Alternativ über das Hilfsskript:</p>
<pre><code>./scripts/build.sh</code></pre>

    <h2>Grafische Ausgabe unter Linux</h2>
    <p>Für Stage und Gazebo wird der lokale X11-Server in den Container durchgereicht. In der Compose-Datei sind dafür bereits <code>DISPLAY</code>, <code>QT_X11_NO_MITSHM</code> und das Volume <code>/tmp/.X11-unix</code> vorgesehen. Zusätzlich muss auf dem Host der Zugriff des Docker-Kontexts auf den X-Server erlaubt werden:</p>
<pre><code>xhost +local:docker</code></pre>

    <p>Danach können grafische Container gestartet werden. Optional kann die Freigabe nach der Nutzung wieder zurückgenommen werden:</p>
<pre><code>xhost -local:docker</code></pre>

    <div class="note">
      <strong>Praktisch relevant:</strong> Ohne <code>xhost +local:docker</code> bleibt das Gazebo- oder Stage-Fenster unter Linux häufig unsichtbar, obwohl der Container selbst korrekt gestartet wurde.
    </div>

    <h2>Services</h2>
    <table>
      <thead>
        <tr>
          <th>Service</th>
          <th>Beschreibung</th>
          <th>Zugeordnete Profile</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><code>floribot-base</code></td>
          <td>Robotik-Kernsystem für den realen Roboter inklusive Start der PLC-Verbindung und des Base-Launchfiles.</td>
          <td><code>robot</code>, <code>base</code></td>
        </tr>
        <tr>
          <td><code>floribot-base-sim</code></td>
          <td>Base-Komponente für den Simulationsbetrieb.</td>
          <td><code>sim</code></td>
        </tr>
        <tr>
          <td><code>floribot-sensors</code></td>
          <td>Sensorintegration für den realen Roboter.</td>
          <td><code>robot</code>, <code>sensors</code></td>
        </tr>
        <tr>
          <td><code>floribot-webteleop</code></td>
          <td>Webbasierte Steuerung für den realen Roboter.</td>
          <td><code>robot</code></td>
        </tr>
        <tr>
          <td><code>floribot-webteleop-sim</code></td>
          <td>Webbasierte Steuerung für die Simulation.</td>
          <td><code>sim</code></td>
        </tr>
        <tr>
          <td><code>floribot-stage</code></td>
          <td>2D-Simulation mit Stage.</td>
          <td><code>stage</code></td>
        </tr>
        <tr>
          <td><code>floribot-gazebo</code></td>
          <td>3D-Simulation mit Gazebo.</td>
          <td><code>sim</code></td>
        </tr>
        <tr>
          <td><code>floribot-sim-backend</code></td>
          <td>Bridge- und Backend-Komponente für die Simulation.</td>
          <td><code>sim</code></td>
        </tr>
      </tbody>
    </table>

    <h2>Docker-Compose-Profile</h2>
    <p>In der aktuellen <code>compose/docker-compose.yml</code> existieren genau die folgenden Profile:</p>
    <p>
      <span class="badge">robot</span>
      <span class="badge">base</span>
      <span class="badge">sensors</span>
      <span class="badge">stage</span>
      <span class="badge">sim</span>
    </p>

    <table>
      <thead>
        <tr>
          <th>Profil</th>
          <th>Startet</th>
          <th>Zweck</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><code>robot</code></td>
          <td><code>floribot-base</code>, <code>floribot-sensors</code>, <code>floribot-webteleop</code></td>
          <td>Kompletter Stack für den realen Roboterbetrieb</td>
        </tr>
        <tr>
          <td><code>base</code></td>
          <td><code>floribot-base</code></td>
          <td>Nur Base-Komponente des realen Systems</td>
        </tr>
        <tr>
          <td><code>sensors</code></td>
          <td><code>floribot-sensors</code></td>
          <td>Nur Sensorcontainer des realen Systems</td>
        </tr>
        <tr>
          <td><code>stage</code></td>
          <td><code>floribot-stage</code></td>
          <td>2D-Simulation mit Stage</td>
        </tr>
        <tr>
          <td><code>sim</code></td>
          <td><code>floribot-base-sim</code>, <code>floribot-webteleop-sim</code>, <code>floribot-gazebo</code>, <code>floribot-sim-backend</code></td>
          <td>3D-Simulationsstack mit Gazebo und Backend</td>
        </tr>
      </tbody>
    </table>

    <div class="warning">
      <strong>Korrektur gegenüber der bisherigen README:</strong> Die Profile <code>core</code>, <code>ui</code> und <code>gazebo</code> existieren in der aktuellen Compose-Datei nicht. Entsprechend sind auch Kommandos wie <code>docker compose --profile core up</code> oder <code>docker compose --profile gazebo up</code> nicht mehr korrekt.
    </div>

    <h2>Profile starten</h2>

    <h3>Kompletter Robotik-Stack</h3>
<pre><code>cd compose
docker compose --profile robot up</code></pre>

    <h3>Nur Base</h3>
<pre><code>cd compose
docker compose --profile base up</code></pre>

    <h3>Nur Sensors</h3>
<pre><code>cd compose
docker compose --profile sensors up</code></pre>

    <h3>Nur Stage</h3>
<pre><code>cd compose
docker compose --profile stage up</code></pre>

    <h3>Simulation mit Gazebo</h3>
<pre><code>cd compose
xhost +local:docker
docker compose --profile sim up</code></pre>

    <h3>Mehrere Profile kombinieren</h3>
    <p>Profile können kombiniert werden, sofern dies fachlich sinnvoll ist. Beispiel:</p>
<pre><code>cd compose
docker compose --profile robot --profile stage up</code></pre>

    <h3>Im Hintergrund starten</h3>
<pre><code>cd compose
docker compose --profile robot up -d</code></pre>

    <h3>In die Konsole eines laufenden Containers wechseln</h3>
<pre><code>docker exec -it &lt;container-name&gt; bash</code></pre>

    <h2>Skripte</h2>
    <p>Im Ordner <code>scripts/</code> stehen Hilfsskripte zur Verfügung:</p>
<pre><code>./scripts/build.sh   # Build aller Container
./scripts/up.sh      # Start der Umgebung im Hintergrund
./scripts/down.sh    # Stoppen aller Container
./scripts/logs.sh    # Logs anzeigen</code></pre>

    <p class="muted">Hinweis: <code>./scripts/up.sh</code> führt intern <code>docker compose up -d</code> ohne explizite Profilangabe aus. Welche Services dabei starten, hängt von der Compose-Konfiguration und den ausgewählten Profilen ab.</p>

    <h2>Logs und Stoppen</h2>

    <h3>Logs anzeigen</h3>
<pre><code>./scripts/logs.sh</code></pre>

    <h3>Alle Container stoppen und entfernen</h3>
<pre><code>cd compose
docker compose down</code></pre>

    <h2>Empfohlener Schnellstart</h2>
    <h3>Realer Roboter</h3>
<pre><code>sudo usermod -aG docker $USER
newgrp docker
cp compose/.env.example compose/.env
./scripts/build.sh
cd compose
docker compose --profile robot up -d</code></pre>

    <h3>Gazebo-Simulation unter Linux</h3>
<pre><code>sudo usermod -aG docker $USER
newgrp docker
cp compose/.env.example compose/.env
./scripts/build.sh
xhost +local:docker
cd compose
docker compose --profile sim up</code></pre>

  </main>
</body>
</html>
