from launch import LaunchDescription
from launch.substitutions import Command
from launch_ros.actions import Node


def generate_launch_description():
    xacro_file = "/ws/src/robot_description/src/urdf/Floribot.urdf.xacro"

    robot_description = {
        "robot_description": Command(["xacro ", xacro_file])
    }

    return LaunchDescription([
        Node(
            package="robot_state_publisher",
            executable="robot_state_publisher",
            parameters=[robot_description],
            output="screen",
        ),
        Node(
            package="joint_state_publisher",
            executable="joint_state_publisher",
            output="screen",
        ),
    ])
