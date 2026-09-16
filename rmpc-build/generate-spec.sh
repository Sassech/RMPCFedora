#!/bin/bash
set -e

# Defaults locales — por si el script se ejecuta sin pasar por build-rpm.sh
PKG_NAME="${PKG_NAME:-rmpc}"
PKG_VERSION="${PKG_VERSION:-0.10.0}"
RPMBUILD_ROOT="${RPMBUILD_ROOT:-/root/rpmbuild}"
SOURCE_DIR="${SOURCE_DIR:-${RPMBUILD_ROOT}/SOURCES/${PKG_NAME}-${PKG_VERSION}}"

CHANGELOG_DATE=$(date +"%a %b %d %Y")
SPEC_FILE="${RPMBUILD_ROOT}/SPECS/${PKG_NAME}.spec"

echo "=== Generando ${PKG_NAME}.spec ==="

mkdir -p "${RPMBUILD_ROOT}/SPECS"

cat > "${SPEC_FILE}" <<EOF
Name:           ${PKG_NAME}
Version:        ${PKG_VERSION}
Release:        1%{?dist}
Summary:        Terminal MPD client inspired by ncmpcpp

License:        GPL-3.0-or-later
URL:            https://github.com/mierak/rmpc
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64

Requires: mpd >= 0.23
Requires: mpc >= 0.34

%description
rmpc is a fast and modern MPD client for the terminal, inspired by ncmpcpp.
Este paquete incluye rmpc y rmpc-setup, un script para configurar MPD
como servicio de usuario con systemd.

%install
# Binario principal
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{_sourcedir}/${PKG_NAME}-${PKG_VERSION}/target/release/${PKG_NAME} \\
    %{buildroot}/usr/bin/${PKG_NAME}

# Script de setup
install -m 0755 %{_sourcedir}/${PKG_NAME}-${PKG_VERSION}/${PKG_NAME}-setup \\
    %{buildroot}/usr/bin/${PKG_NAME}-setup

# Templates de configuración
mkdir -p %{buildroot}/usr/share/${PKG_NAME}
install -m 0644 %{_sourcedir}/${PKG_NAME}-${PKG_VERSION}/config/mpd.conf.tpl \\
    %{buildroot}/usr/share/${PKG_NAME}/mpd.conf.tpl
install -m 0644 %{_sourcedir}/${PKG_NAME}-${PKG_VERSION}/config/rmpc.config.ron.tpl \\
    %{buildroot}/usr/share/${PKG_NAME}/rmpc.config.ron.tpl

%files
/usr/bin/${PKG_NAME}
/usr/bin/${PKG_NAME}-setup
/usr/share/${PKG_NAME}/mpd.conf.tpl
/usr/share/${PKG_NAME}/rmpc.config.ron.tpl

%post
cat <<MESSAGE

============================================================
        rmpc instalado correctamente
============================================================

Para configurar MPD en tu usuario, ejecuta:

    rmpc-setup

Esto configurará MPD como servicio de usuario systemd y creará
los archivos de configuración necesarios.

Después, ejecuta 'rmpc' para usar el cliente.

MESSAGE

%postun
if [ \$1 -eq 0 ]; then
    cat <<MESSAGE

rmpc ha sido desinstalado.

Para eliminar la configuración de MPD:
    systemctl --user stop mpd
    systemctl --user disable mpd
    rm -rf ~/.config/mpd ~/.config/rmpc

MESSAGE
fi

%changelog
* ${CHANGELOG_DATE} rmpc packager - ${PKG_VERSION}-1
- Paquete inicial con servicio MPD a nivel de usuario
- Script rmpc-setup para configuración por usuario
- MPD configurado como servicio systemd de usuario
- Conexión rmpc->MPD por FIFO socket
- Templates de configuración instalados en /usr/share/rmpc/
EOF

echo "[OK] Spec generado: ${SPEC_FILE}"
echo "=== Ejecutando rpmbuild ==="

# Copiar templates al SOURCE_DIR para que rpmbuild los encuentre
mkdir -p "${SOURCE_DIR}/config"
cp "$(dirname "${BASH_SOURCE[0]}")/config/mpd.conf.tpl"         "${SOURCE_DIR}/config/"
cp "$(dirname "${BASH_SOURCE[0]}")/config/rmpc.config.ron.tpl"  "${SOURCE_DIR}/config/"

rpmbuild -bb "${SPEC_FILE}"
echo "[OK] RPM construido"
