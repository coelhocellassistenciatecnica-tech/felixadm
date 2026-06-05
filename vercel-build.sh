#!/bin/bash

# Evitar erros de permissão do Git no ambiente Vercel
git config --global --add safe.directory /vercel/path0
git config --global --add safe.directory /vercel/path0/flutter

# Instalar Flutter se não existir
if [ ! -d "flutter" ]; then
  echo "Baixando Flutter SDK..."
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz -o flutter.tar.xz
  tar xf flutter.tar.xz
  rm flutter.tar.xz
fi

export PATH="$PATH:`pwd`/flutter/bin"

# Configurações para rodar como root na Vercel sem avisos
export CHROME_EXECUTABLE=/usr/bin/google-chrome

echo "Configurando Flutter..."
flutter config --no-analytics
flutter config --enable-web

echo "Instalando dependências..."
flutter pub get

echo "Iniciando build web..."
flutter build web --release --base-href "/"
