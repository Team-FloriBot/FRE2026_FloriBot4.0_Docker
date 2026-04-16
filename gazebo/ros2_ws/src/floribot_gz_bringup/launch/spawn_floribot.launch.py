from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
from virtual_maize_field import get_spawner_launch_file


def generate_launch_description():
    robot_model = PathJoinSubstitution([
        FindPackageShare("floribot_gz_description"),
        "models",
        "floribot_test.sdf",
    ])

    spawn_robot = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([get_spawner_launch_file()]),
        launch_arguments={
            "world": "virtual_maize_field",
            "file": robot_model,
            "entity_name": "floribot4",
            "allow_renaming": "False",
        }.items(),
    )

    return LaunchDescription([
        spawn_robot,
    ])
