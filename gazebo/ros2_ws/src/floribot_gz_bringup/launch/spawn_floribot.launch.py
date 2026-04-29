from launch import LaunchDescription
from launch.actions import ExecuteProcess


def generate_launch_description():
    spawn_robot = ExecuteProcess(
        cmd=[
            "bash", "-lc",
            "source /opt/ros/jazzy/setup.bash && "
            "source /ws/install/setup.bash && "
            "xacro /ws/src/robot_description/src/urdf/Floribot.urdf.xacro > /tmp/floribot_gz.urdf && "
            "ros2 run ros_gz_sim create "
            "-world virtual_maize_field "
            "-name FloriBot "
            "-file /tmp/floribot_gz.urdf "
            "-x -1.3631752758808973 "
            "-y -3.460156696047507 "
            "-z 0.6499999999999999 "
            "-R 0.0 "
            "-P 0.0 "
            "-Y 1.5980816365126524"
        ],
        output="screen",
    )

    return LaunchDescription([
        spawn_robot,
    ])
