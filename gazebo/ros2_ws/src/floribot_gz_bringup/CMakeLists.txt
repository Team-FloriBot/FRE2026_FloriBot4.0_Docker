cmake_minimum_required(VERSION 3.8)
project(floribot_gz_bringup)

find_package(ament_cmake REQUIRED)

install(DIRECTORY
  launch
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
