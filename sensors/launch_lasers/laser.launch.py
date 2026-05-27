import os
import sys
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    ld = LaunchDescription()
    sick_scan_pkg_prefix = get_package_share_directory('sick_scan_xd')
    
    # Dateinamen der Configs
    launchfile_front = "front_laser_config.launch" 
    launchfile_rear = "rear_laser_config.launch"
    
    # Vollständige Pfade
    launch_file_path_front = os.path.join(sick_scan_pkg_prefix, 'launch', launchfile_front)
    launch_file_path_rear = os.path.join(sick_scan_pkg_prefix, 'launch', launchfile_rear)
    
    # Separate Argumenten-Listen für beide Nodes
    node_arguments_front = [launch_file_path_front]
    node_arguments_rear = [launch_file_path_rear]
    
    # Optionale Kommandozeilenargumente an beide Nodes anhängen (name:=value Syntax)
    for arg in sys.argv:
        if len(arg.split(":=")) == 2:
            node_arguments_front.append(arg)
            node_arguments_rear.append(arg)
    
    # Node-Definition für den Front-Laser
    node_front = Node(
        package='sick_scan_xd',
        executable='sick_generic_caller',
        name='sick_front',  # Eigener Node-Name zur Vermeidung von Konflikten
        output='screen',
        arguments=node_arguments_front
    )
    
    # Node-Definition für den Heck-Laser
    node_rear = Node(
        package='sick_scan_xd',
        executable='sick_generic_caller',
        name='sick_rear',  # Eigener Node-Name zur Vermeidung von Konflikten
        output='screen',
        arguments=node_arguments_rear
    )
    
    # Beide Nodes zur Launch-Description hinzufügen
    ld.add_action(node_front)
    ld.add_action(node_rear)
    
    return ld