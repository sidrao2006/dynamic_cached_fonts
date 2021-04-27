FROM cirrusci/flutter:stable

WORKDIR /app

COPY pubspec.* ./
COPY example/pubspec.* ./example/

RUN flutter pub get
