FROM cirrusci/flutter:stable

WORKDIR /app

COPY pubspec.* ./
COPY example/pubspec.* ./example/

RUN flutter pub get

# Linux development

# RUN flutter config --enable-linux-desktop
# RUN apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev
