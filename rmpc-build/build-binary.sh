#!/bin/bash
set -e

echo "=== Compilando ${PKG_NAME} con cargo ==="

cd "${SOURCE_DIR}"
cargo build --release

echo "[OK] Binario compilado: ${SOURCE_DIR}/target/release/${PKG_NAME}"
