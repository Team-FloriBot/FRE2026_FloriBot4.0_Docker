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
            "bash", "-lc",
            "source /ws/install/setup.bash && "
            "ros2 run virtual_maize_field generate_world fre22_task_navigation_mini"
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
