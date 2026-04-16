from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from virtual_maize_field import get_spawner_launch_file


def generate_launch_description():
    spawn_robot = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([get_spawner_launch_file()]),
        launch_arguments={
            "robot_name": "floribot4",
        }.items(),
    )

    return LaunchDescription([spawn_robot])
