from launch import LaunchDescription
from launch.actions import ExecuteProcess, IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    xacro_file = PathJoinSubstitution([
        FindPackageShare("floribot_gz_description"),
        "urdf",
        "Floribot_gz.urdf.xacro",
    ])

    world_launch = PathJoinSubstitution([
        FindPackageShare("virtual_maize_field"),
        "launch",
        "simulation.launch.py",
    ])

    robot_description = {
        "robot_description": Command(["xacro ", xacro_file])
    }

    generate_world = ExecuteProcess(
        cmd=[
            "bash", "-lc",
            "source /ws/install/setup.bash && "
            "ros2 run virtual_maize_field generate_world fre22_task_navigation_mini"
        ],
        output="screen",
    )

    state_publisher = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        parameters=[robot_description],
        output="screen",
    )

    spawn_robot = Node(
        package="ros_gz_sim",
        executable="create",
        arguments=[
            "-name", "floribot4",
            "-topic", "robot_description",
            "-x", "0.0",
            "-y", "0.0",
            "-z", "0.3",
        ],
        output="screen",
    )

    return LaunchDescription([
        generate_world,
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(world_launch),
        ),
        state_publisher,
        TimerAction(
            period=5.0,
            actions=[spawn_robot],
        ),
    ])
