#!/bin/bash
set -e

RPMBUILD_ROOT=/root/rpmbuild
USERNAME="Sassech"
EMAIL="lainstroop@gmail.com"

# Crear árbol rpmbuild
rpmdev-setuptree --tree=$RPMBUILD_ROOT

# Copiar proyecto a SOURCES
mkdir -p $RPMBUILD_ROOT/SOURCES/rmpc-0.10.0
cp -r ./* $RPMBUILD_ROOT/SOURCES/rmpc-0.10.0/

# Compilar rmpc con cargo
cd $RPMBUILD_ROOT/SOURCES/rmpc-0.10.0
cargo build --release

# Crear script de configuración inicial
cat > $RPMBUILD_ROOT/SOURCES/rmpc-0.10.0/rmpc-setup <<'SETUP_SCRIPT'
#!/bin/bash
# Script de configuración inicial de rmpc y MPD para el usuario

echo "=== Configurando rmpc y MPD para $USER ==="

# Crear directorio de música
MUSIC_DIR="$HOME/Music"
mkdir -p "$MUSIC_DIR"
echo "✓ Directorio de música: $MUSIC_DIR"

# Crear directorios necesarios para MPD
mkdir -p "$HOME/.config/mpd/playlists"

# Configurar MPD si no existe
if [ ! -f "$HOME/.config/mpd/mpd.conf" ]; then
    cat > "$HOME/.config/mpd/mpd.conf" <<CONF
music_directory    "$MUSIC_DIR"
playlist_directory "$HOME/.config/mpd/playlists"
db_file            "$HOME/.config/mpd/database"
log_file           "$HOME/.config/mpd/log"
pid_file           "$HOME/.config/mpd/pid"
state_file         "$HOME/.config/mpd/state"
sticker_file       "$HOME/.config/mpd/sticker.sql"

auto_update         "yes"
bind_to_address    "127.0.0.1"
port               "6600"

audio_output {
    type            "pipewire"
    name            "PipeWire Sound Server"
}

audio_output {
    type            "pulse"
    name            "PulseAudio Sound Server"
}
CONF
    echo "✓ Configuración de MPD creada"
else
    echo "✓ Configuración de MPD ya existe"
fi

# Crear directorio de configuración de rmpc
mkdir -p "$HOME/.config/rmpc"

# Crear configuración de rmpc si no existe
if [ ! -f "$HOME/.config/rmpc/config.ron" ]; then
    if command -v rmpc &> /dev/null; then
        rmpc config > "$HOME/.config/rmpc/config.ron" 2>/dev/null || echo "// Configuración por defecto de rmpc" > "$HOME/.config/rmpc/config.ron"
        echo "✓ Configuración de rmpc creada"
    fi
else
    echo "✓ Configuración de rmpc ya existe"
fi

# Crear servicio systemd de usuario para MPD
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/mpd.service" <<SERVICE
[Unit]
Description=Music Player Daemon
Documentation=man:mpd(1) man:mpd.conf(5)
After=network.target sound.target

[Service]
Type=notify
ExecStart=/usr/bin/mpd --no-daemon %h/.config/mpd/mpd.conf
Restart=on-failure
RestartSec=5

# Habilitar logs
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SERVICE
echo "✓ Servicio systemd de usuario creado"

# Detener cualquier instancia de MPD que esté corriendo manualmente
pkill -u "$USER" mpd 2>/dev/null || true
sleep 1

# Recargar systemd user daemon
systemctl --user daemon-reload
echo "✓ Systemd recargado"

# Habilitar MPD para que inicie automáticamente
systemctl --user enable mpd.service
echo "✓ MPD habilitado para inicio automático"

# Iniciar MPD
systemctl --user start mpd.service
echo "✓ Intentando iniciar MPD..."

# Esperar un momento para que MPD inicie
sleep 2

# Verificar el estado
if systemctl --user is-active --quiet mpd.service; then
    echo "✓ MPD está funcionando correctamente"
else
    echo "✗ MPD falló al iniciar. Verificando el error..."
    echo ""
    echo "=== Log de MPD ==="
    if [ -f "$HOME/.config/mpd/log" ]; then
        tail -20 "$HOME/.config/mpd/log"
    else
        journalctl --user -u mpd.service -n 20 --no-pager
    fi
    echo ""
    echo "=== Estado del servicio ==="
    systemctl --user status mpd.service --no-pager
    echo ""
    echo "Para más información, ejecuta:"
    echo "  journalctl --user -u mpd.service -f"
    exit 1
fi

# Habilitar linger para que MPD se inicie al arrancar el sistema
if command -v loginctl &> /dev/null; then
    if sudo -n loginctl enable-linger "$USER" 2>/dev/null; then
        echo "✓ MPD se iniciará automáticamente al arrancar el sistema"
    else
        echo "⚠ No se pudo habilitar linger (requiere sudo). MPD solo se iniciará al hacer login."
        echo "  Para habilitarlo manualmente: sudo loginctl enable-linger $USER"
    fi
fi

echo ""
echo "=== Configuración completada ==="
echo "Puedes ejecutar 'rmpc' para iniciar el cliente MPD"
echo ""
echo "Comandos útiles:"
echo "  systemctl --user status mpd     - Ver estado de MPD"
echo "  systemctl --user restart mpd    - Reiniciar MPD"
echo "  systemctl --user stop mpd       - Detener MPD"
echo "  journalctl --user -u mpd -f     - Ver logs en tiempo real"
echo "  mpc update                      - Actualizar base de datos de música"
echo "  rmpc                            - Iniciar rmpc"
SETUP_SCRIPT

chmod +x $RPMBUILD_ROOT/SOURCES/rmpc-0.10.0/rmpc-setup

# Generar SPEC
mkdir -p $RPMBUILD_ROOT/SPECS
cat > $RPMBUILD_ROOT/SPECS/rmpc.spec <<EOF
Name:           rmpc
Version:        0.10.0
Release:        1%{?dist}
Summary:        Terminal MPD client inspired by ncmpcpp

License:        GPL-3.0-or-later
URL:            https://github.com/mierak/rmpc
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64
Requires:       mpd >= 0.23

%description
rmpc is a fast and modern MPD client for the terminal, inspired by ncmpcpp.
This package includes rmpc and a setup script to configure MPD as a user service.

%install
# Instalar binario principal
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{_sourcedir}/rmpc-0.10.0/target/release/rmpc %{buildroot}/usr/bin/rmpc

# Instalar script de configuración
install -m 0755 %{_sourcedir}/rmpc-0.10.0/rmpc-setup %{buildroot}/usr/bin/rmpc-setup

%files
/usr/bin/rmpc
/usr/bin/rmpc-setup

%post
cat <<MESSAGE

╔════════════════════════════════════════════════════════════╗
║        rmpc instalado correctamente                        ║
╚════════════════════════════════════════════════════════════╝

Para configurar MPD para tu usuario, ejecuta:

    rmpc-setup

Esto configurará MPD como servicio de usuario y creará los
directorios y archivos de configuración necesarios.

Después podrás ejecutar 'rmpc' para usar el cliente.

MESSAGE

%postun
if [ \$1 -eq 0 ]; then
    cat <<MESSAGE

rmpc ha sido desinstalado.

Si deseas eliminar la configuración de MPD, ejecuta:
    systemctl --user stop mpd
    systemctl --user disable mpd
    rm -rf ~/.config/mpd ~/.config/rmpc

MESSAGE
fi

%changelog
* $(date +"%a %b %d %Y") $USERNAME <$EMAIL> - 0.10.0-1
- Initial package with user-level MPD service
- Added rmpc-setup script for user configuration
- MPD configured as systemd user service
EOF

# Construir el RPM
rpmbuild -bb $RPMBUILD_ROOT/SPECS/rmpc.spec

# Copiar RPM al directorio compartido
mkdir -p /output
cp $RPMBUILD_ROOT/RPMS/x86_64/*.rpm /output/

echo ""
echo "=== RPM generado exitosamente ==="
ls -lh /output/*.rpm