cmake_minimum_required(VERSION 3.8)
project(floribot_gz_description)

find_package(ament_cmake REQUIRED)

install(DIRECTORY
  urdf
  meshes
  launch
  models
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
