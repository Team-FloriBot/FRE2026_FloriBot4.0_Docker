from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    bringup_launch_dir = os.path.join(
        get_package_share_directory("floribot_gz_bringup"),
        "launch",
    )

    description_launch_dir = os.path.join(
        get_package_share_directory("floribot_gz_description"),
        "launch",
    )

    world_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(bringup_launch_dir, "maize_world.launch.py")
        )
    )

    robot_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(bringup_launch_dir, "spawn_floribot.launch.py")
        )
    )

    view_description_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(description_launch_dir, "view_description.launch.py")
        )
    )

    rviz = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz",
        output="screen",
        parameters=[{"use_sim_time": True}],
    )

    return LaunchDescription([
        world_launch,

        view_description_launch,

        TimerAction(
            period=8.0,
            actions=[robot_launch],
        ),

        TimerAction(
            period=10.0,
            actions=[rviz],
        ),
    ])
