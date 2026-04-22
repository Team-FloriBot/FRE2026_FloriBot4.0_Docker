#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass

import rclpy
from rclpy.node import Node

from base.msg import Angle, Wheels
from std_msgs.msg import Float64

@dataclass
class WheelState:
    front_left: float = 0.0
    front_right: float = 0.0
    rear_left: float = 0.0
    rear_right: float = 0.0


class SimBackendNode(Node):
    def __init__(self) -> None:
        super().__init__("sim_backend")

        self.declare_parameter("publish_rate_hz", 20.0)
        self.declare_parameter("speed_response_alpha", 0.25)
        self.declare_parameter("body_angle_gain", 0.02)
        self.declare_parameter("body_angle_limit_rad", 0.35)
        self.declare_parameter("publish_body_angle", True)
        self.declare_parameter("body_angle_fixed_rad", 0.0)

        publish_rate_hz = float(self.get_parameter("publish_rate_hz").value)
        self.speed_response_alpha = float(self.get_parameter("speed_response_alpha").value)
        self.body_angle_gain = float(self.get_parameter("body_angle_gain").value)
        self.body_angle_limit_rad = float(self.get_parameter("body_angle_limit_rad").value)
        self.publish_body_angle = bool(self.get_parameter("publish_body_angle").value)
        self.body_angle_fixed_rad = float(self.get_parameter("body_angle_fixed_rad").value)

        if publish_rate_hz <= 0.0:
            raise ValueError("publish_rate_hz must be > 0")

        self.target_state = WheelState()
        self.actual_state = WheelState()

        self.target_speed_sub = self.create_subscription(
            Wheels,
            "engine/targetSpeed",
            self.target_speed_callback,
            10,
        )

        self.actual_speed_pub = self.create_publisher(
            Wheels,
            "engine/actualSpeed",
            10,
        )

        self.body_angle_pub = self.create_publisher(
            Angle,
            "/sensors/bodyAngle",
            10,
        )

        period = 1.0 / publish_rate_hz
        self.timer = self.create_timer(period, self.on_timer)

        self.get_logger().info("sim_backend started")
        self.get_logger().info(
            f"Publishing engine/actualSpeed and /sensors/bodyAngle at {publish_rate_hz:.1f} Hz"
        )

    def target_speed_callback(self, msg: Wheels) -> None:
        self.target_state.front_left = msg.front_left
        self.target_state.front_right = msg.front_right
        self.target_state.rear_left = msg.rear_left
        self.target_state.rear_right = msg.rear_right

    def first_order_update(self, current: float, target: float) -> float:
        alpha = self.speed_response_alpha
        return current + alpha * (target - current)

    def clamp(self, value: float, lower: float, upper: float) -> float:
        return max(lower, min(value, upper))

    def estimate_body_angle(self) -> float:
        if not self.publish_body_angle:
            return self.body_angle_fixed_rad

        front_mean = 0.5 * (
            self.actual_state.front_left + self.actual_state.front_right
        )
        rear_mean = 0.5 * (
            self.actual_state.rear_left + self.actual_state.rear_right
        )

        angle = self.body_angle_gain * (front_mean - rear_mean)
        return self.clamp(angle, -self.body_angle_limit_rad, self.body_angle_limit_rad)

    def on_timer(self) -> None:
        self.actual_state.front_left = self.first_order_update(
            self.actual_state.front_left,
            self.target_state.front_left,
        )
        self.actual_state.front_right = self.first_order_update(
            self.actual_state.front_right,
            self.target_state.front_right,
        )
        self.actual_state.rear_left = self.first_order_update(
            self.actual_state.rear_left,
            self.target_state.rear_left,
        )
        self.actual_state.rear_right = self.first_order_update(
            self.actual_state.rear_right,
            self.target_state.rear_right,
        )

        now = self.get_clock().now().to_msg()

        wheels_msg = Wheels()
        wheels_msg.header.stamp = now
        wheels_msg.front_left = self.actual_state.front_left
        wheels_msg.front_right = self.actual_state.front_right
        wheels_msg.rear_left = self.actual_state.rear_left
        wheels_msg.rear_right = self.actual_state.rear_right
        self.actual_speed_pub.publish(wheels_msg)

        angle_msg = Angle()
        angle_msg.header.stamp = now
        angle_msg.angle = self.estimate_body_angle()
        self.body_angle_pub.publish(angle_msg)


def main(args: list[str] | None = None) -> None:
    rclpy.init(args=args)
    node = SimBackendNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
