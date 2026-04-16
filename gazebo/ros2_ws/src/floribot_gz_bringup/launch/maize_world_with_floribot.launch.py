from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource


def generate_launch_description():
    world_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            "/ws/src/floribot_gz_bringup/launch/maize_world.launch.py"
        )
    )

    robot_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            "/ws/src/floribot_gz_bringup/launch/spawn_floribot.launch.py"
        )
    )

    return LaunchDescription([
        world_launch,
        TimerAction(
            period=8.0,
            actions=[robot_launch],
        ),
    ])
