from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, ExecuteProcess
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    return LaunchDescription([
        # Welt generieren
        ExecuteProcess(
            cmd=['ros2', 'run', 'virtual_maize_field', 'generate_world', 'fre22_task_navigation_mini'],
            output='screen'
        ),
        # Gazebo starten
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(get_package_share_directory('ros_gz_sim'), 'launch', 'gz_sim.launch.py')
            ),
            launch_arguments={'gz_args': '-r /root/.ros/virtual_maize_field/generated.world'}.items()
        ),
        # FloriBot spawnen
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(get_package_share_directory('floribot_gz_bringup'), 'launch', 'spawn_floribot.launch.py')
            )
        )
    ])