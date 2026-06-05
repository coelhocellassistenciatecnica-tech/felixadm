#!/bin/bash

# Instalar Flutter
if [ ! -d "flutter" ]; then
  curl -C - -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz
  tar xf flutter_linux_3.22.2-stable.tar.xz
  rm flutter_linux_3.22.2-stable.tar.xz
fi

export PATH="$PATH:`pwd`/flutter/bin"

# Build Flutter Web
flutter config --enable-web
flutter pub get
flutter build web --release
