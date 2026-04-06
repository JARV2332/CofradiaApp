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
flutter doctor
flutter pub get

# Opcional en Vercel: Environment Variables SUPABASE_URL y SUPABASE_ANON_KEY
build_args=(build web --release)
if [[ -n "${SUPABASE_URL:-}" ]]; then
  build_args+=(--dart-define="SUPABASE_URL=${SUPABASE_URL}")
  echo ">>> SUPABASE_URL definida (build)"
fi
if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
  build_args+=(--dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")
  echo ">>> SUPABASE_ANON_KEY definida (build)"
fi

flutter "${build_args[@]}"

echo ">>> Listo: build/web"
