#!/usr/bin/env bash
# Compila Flutter Web en Vercel (Linux). Fin de linea LF (.gitattributes).
# La primera vez clona el SDK (tarda varios minutos).
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

# Proyecto Supabase activo (forzado: si en Vercel quedaron env del proyecto viejo,
# borra SUPABASE_URL / SUPABASE_ANON_KEY en Settings → Environment Variables)
export SUPABASE_URL="https://wtngrplmuehuabbdvtjb.supabase.co"
export SUPABASE_ANON_KEY="sb_publishable_rL9ACkl0b1MCpIJaHPXthw__E0z_Cm9"
echo ">>> Supabase URL (build): ${SUPABASE_URL}"

build_args=(build web --release)
build_args+=(--dart-define="SUPABASE_URL=${SUPABASE_URL}")
build_args+=(--dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")

flutter "${build_args[@]}"

echo ">>> Listo: build/web"
