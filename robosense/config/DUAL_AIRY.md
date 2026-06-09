# Dual RoboSense AIRY configuration

| Position | Device IP | MSOP | DIFOP | IMU | Frame |
|---|---:|---:|---:|---:|---|
| Front | 192.168.0.200 | 6699 | 7788 | 6688 | robosense_front_link |
| Rear | 192.168.0.201 | 6700 | 7789 | 6689 | robosense_rear_link |

The RoboSense SDK does not select a lidar by its device/sender IP.
It binds UDP destination ports.

Therefore the rear AIRY must be configured to send to ports
6700/7789/6689. The front AIRY retains 6699/7788/6688.

ROS namespaces:

- `/sensors/robosense/front`
- `/sensors/robosense/rear`

Driver nodes:

- `/sensors/robosense/front/robosense_front_driver`
- `/sensors/robosense/rear/robosense_rear_driver`

Point clouds and scans:

- `/sensors/robosense/front/points`
- `/sensors/robosense/front/scan`
- `/sensors/robosense/rear/points`
- `/sensors/robosense/rear/scan`
