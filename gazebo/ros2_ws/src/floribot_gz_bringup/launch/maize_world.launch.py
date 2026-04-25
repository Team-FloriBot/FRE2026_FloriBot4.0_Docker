from launch import LaunchDescription
from launch.actions import ExecuteProcess, IncludeLaunchDescription, RegisterEventHandler
from launch.event_handlers import OnProcessExit
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    world_launch = PathJoinSubstitution([
        FindPackageShare("virtual_maize_field"),
        "launch",
        "simulation.launch.py",
    ])

    generate_world = ExecuteProcess(
        cmd=[
            "bash",
            "-lc",
            """
            source /ws/install/setup.bash && \
            ros2 run virtual_maize_field generate_world fre22_task_navigation_mini && \
            python3 -c '
from pathlib import Path
import re

plugin = \"\"\"
    <plugin filename=\\"gz-sim-sensors-system\\"
            name=\\"gz::sim::systems::Sensors\\">
      <render_engine>ogre2</render_engine>
    </plugin>
\"\"\"

roots = [
    Path(\\"/ws/src/virtual_maize_field\\"),
    Path(\\"/ws/install/virtual_maize_field/share/virtual_maize_field\\"),
]

for root in roots:
    if not root.exists():
        continue

    for file in list(root.rglob(\\"*.sdf\\")) + list(root.rglob(\\"*.world\\")):
        text = file.read_text()

        if \\"gz-sim-sensors-system\\" in text:
            continue

        if \\"<world\\" not in text:
            continue

        text = re.sub(
            r\\"(<world[^>]*>)\\",
            r\\"\\\\1\\\\n\\" + plugin,
            text,
            count=1,
        )

        file.write_text(text)
        print(f\\"Patched Gazebo sensors plugin into: {file}\\")
'
            """
        ],
        output="screen",
    )

    start_world = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(world_launch)
    )

    return LaunchDescription([
        generate_world,
        RegisterEventHandler(
            OnProcessExit(
                target_action=generate_world,
                on_exit=[start_world],
            )
        ),
    ])
