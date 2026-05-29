from launch import LaunchDescription
from launch.actions import SetEnvironmentVariable, DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
from pathlib import Path

def generate_launch_description():

    # 1. Deklariere das Argument für den Namespace
    namespace_arg = DeclareLaunchArgument(
        'xsens_namespace',
        default_value='/sensors/xsens',
        description='Namespace for the Xsens node'
    )

    # 2. Definiere die Konfiguration, um auf das Argument zuzugreifen
    xsens_ns = LaunchConfiguration('xsens_namespace')

    ld = LaunchDescription()

    # Logging Einstellungen
    ld.add_action(SetEnvironmentVariable('RCUTILS_LOGGING_USE_STDOUT', '1'))
    ld.add_action(SetEnvironmentVariable('RCUTILS_LOGGING_BUFFERED_STREAM', '1'))

    # Füge das Argument zum Launch-Description hinzu
    ld.add_action(namespace_arg)

    parameters_file_path = Path(get_package_share_directory('xsens_mti_ros2_driver'), 'param', 'xsens_mti_node.yaml')
    
    # 3. Weise den Namespace der Node zu
    xsens_mti_node = Node(
            package='xsens_mti_ros2_driver',
            executable='xsens_mti_node',
            name='xsens_mti_node',
            namespace=xsens_ns,
            output='screen',
            parameters=[parameters_file_path],
            arguments=[],
            respawn=True,
            respawn_delay=3.0
            )
    ld.add_action(xsens_mti_node)

    return ld