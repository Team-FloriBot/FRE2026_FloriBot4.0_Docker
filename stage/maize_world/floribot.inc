define hokuyo_laser ranger
(
  sensor(
    range [ 0 30 ]
    fov 180.0
    samples 720
  )

  # generic model properties
  color "blue"
  size [ 0.07 0.07 0.07 ]
)

define hokuyo_body hokuyo_laser
(
  block(
    points 4
    point[0] [ 0 0 ]
    point[1] [ 0 1 ]
    point[2] [ 1 1 ]
    point[3] [ 1 0 ]
    z [0 0.035]
  )
)

define floribot position
(
  size [0.55 0.4 0.4]

  block(
    points 4
    point[0] [ 0 0 ]
    point[1] [ 0 1 ]
    point[2] [ 1 1 ]
    point[3] [ 1 0 ]
    z [0 0.2]
  )

  gui_nose 1
  mass 25.0
  drive "omni"
  localization "odom"
  odom_error [0.03 0.03 0.00 0.05]

  # Laser vorne
  hokuyo_body(
    pose [ 0.3 0 -0.3 0 ]
    name "laser_front"
  )

  # Laser hinten (180° gedreht)
  hokuyo_body(
    pose [ -0.3 0 -0.3 180 ]
    name "laser_rear"
  )
)
