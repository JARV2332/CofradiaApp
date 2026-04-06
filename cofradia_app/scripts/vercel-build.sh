#!/usr/bin/env bash
# Compila Flutter Web en Vercel (Linux). La primera vez clona el SDK (tarda varios minutos).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="$PATH:$ROOT/flutter/bin"
export FLUTTER_ROOT="$ROOT/flutter"

if [[ ! -x "$ROOT/flutter/bin/flutter" ]]; then
  echo ">>> Descargando Flutter (stable, shallow clone)..."
  rm -rf "$ROOT/flutter"
  git clone --branch stable --depth 1 https://github.com/flutter/flutter.git "$ROOT/flutter"
fi

flutter config --no-analytics
flutter precache --web
flutter doctor -v
flutter pub get
flutter build web --release

echo ">>> Listo: build/web"
