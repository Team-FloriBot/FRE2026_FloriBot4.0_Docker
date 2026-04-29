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
            "-name FloriBot "
            "-file /tmp/floribot_gz.urdf "
            "-x 0 "
            "-y 0 "
            "-z 0.65 "
            "-R 0.0 "
            "-P 0.0 "
            "-Y 0.0"
        ],
        output="screen",
    )

    return LaunchDescription([
        spawn_robot,
    ])
