from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command

from virtual_maize_field import get_spawner_launch_file


def generate_launch_description():
    robot_urdf = Command([
        "xacro ",
        "/ws/src/robot_description/src/urdf/Floribot.urdf.xacro",
    ], on_stderr='warn')

    spawn_robot = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(get_spawner_launch_file()),
        launch_arguments={
            "world": "virtual_maize_field",
            "model_string": robot_urdf,
            "entity_name": "FloriBot",
            "allow_renaming": "True",
        }.items(),
    )

    return LaunchDescription([
        spawn_robot,
    ])
