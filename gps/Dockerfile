FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    python3-serial \
    udev \
    usbutils \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-nmea-navsat-driver \
    && rm -rf /var/lib/apt/lists/*

COPY gps/entrypoint.sh /entrypoint.sh
COPY gps/start_gps.sh /start_gps.sh

RUN chmod +x /entrypoint.sh /start_gps.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_gps.sh"]
