#!/bin/bash

# Descargar la última versión estable de Flutter si no está descargada
if cd flutter; then
  git pull
  cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Añadir Flutter al PATH para que Vercel pueda usarlo
export PATH="$PATH:`pwd`/flutter/bin"

# Instalar dependencias y compilar
echo "Instalando dependencias..."
flutter pub get

echo "Compilando para web..."
flutter build web --release
