#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SOURCE_DIR}/rmpc-setup"

echo "=== Generating rmpc-setup ==="

# ── Cabecera del script ──────────────────────────────────────
cat > "${SETUP_SCRIPT}" <<'HEADER'
#!/bin/bash
set -e

echo "=== Setting up MPD and rmpc for ${USER} ==="

CURRENT_UID=$(id -u)
MUSIC_DIR="${HOME}/Music"
MPD_FIFO="/run/user/${CURRENT_UID}/mpd.fifo"
MPD_CONF_DIR="${HOME}/.config/mpd"
RMPC_CONF_DIR="${HOME}/.config/rmpc"
SYSTEMD_DIR="${HOME}/.config/systemd/user"

mkdir -p "${MPD_CONF_DIR}/playlists" "${RMPC_CONF_DIR}" "${SYSTEMD_DIR}"
echo "[OK] Directorios creados"

HEADER

# ── Bloque: instalar config MPD desde template ───────────────
cat >> "${SETUP_SCRIPT}" <<'MPD_BLOCK'
if [ ! -f "${MPD_CONF_DIR}/mpd.conf" ]; then
    sed \
        -e "s|{{MUSIC_DIR}}|${MUSIC_DIR}|g" \
        -e "s|{{MPD_CONF_DIR}}|${MPD_CONF_DIR}|g" \
        -e "s|{{MPD_FIFO}}|${MPD_FIFO}|g" \
        /usr/share/rmpc/mpd.conf.tpl > "${MPD_CONF_DIR}/mpd.conf"
    echo "[OK] Configuración MPD creada: ${MPD_CONF_DIR}/mpd.conf"
else
    echo "[OK] Configuración MPD ya existe, omitiendo"
fi

MPD_BLOCK

# ── Bloque: instalar config rmpc desde template ──────────────
cat >> "${SETUP_SCRIPT}" <<'RMPC_BLOCK'
if [ ! -f "${RMPC_CONF_DIR}/config.ron" ]; then
    sed \
        -e "s|{{MPD_FIFO}}|${MPD_FIFO}|g" \
        -e "s|{{MUSIC_DIR}}|${MUSIC_DIR}|g" \
        -e "s|{{HOME}}|${HOME}|g" \
        /usr/share/rmpc/rmpc.config.ron.tpl > "${RMPC_CONF_DIR}/config.ron"
    echo "[OK] Configuración rmpc creada: ${RMPC_CONF_DIR}/config.ron"
else
    echo "[OK] Configuración rmpc ya existe, omitiendo"
fi

RMPC_BLOCK

# ── Bloque: servicio systemd ─────────────────────────────────
cat >> "${SETUP_SCRIPT}" <<'SYSTEMD_BLOCK'
cat > "${SYSTEMD_DIR}/mpd.service" <<SERVICE
[Unit]
Description=Music Player Daemon
Documentation=man:mpd(1) man:mpd.conf(5)
After=network.target sound.target

[Service]
Type=notify
ExecStart=/usr/bin/mpd --no-daemon %h/.config/mpd/mpd.conf
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SERVICE
echo "[OK] Servicio systemd creado"

SYSTEMD_BLOCK

# ── Bloque: arrancar MPD ─────────────────────────────────────
cat >> "${SETUP_SCRIPT}" <<'START_BLOCK'
pkill -u "${USER}" mpd 2>/dev/null || true
sleep 1

systemctl --user daemon-reload
echo "[OK] Systemd recargado"

systemctl --user enable mpd.service
echo "[OK] MPD habilitado para inicio automático"

systemctl --user start mpd.service
echo "[INFO] Iniciando MPD..."
sleep 2

if systemctl --user is-active --quiet mpd.service; then
    echo "[OK] MPD funcionando correctamente"
else
    echo "[ERROR] MPD no pudo iniciarse. Revisando logs..."
    echo ""
    echo "=== Log MPD ==="
    if [ -f "${MPD_CONF_DIR}/log" ]; then
        tail -20 "${MPD_CONF_DIR}/log"
    else
        journalctl --user -u mpd.service -n 20 --no-pager
    fi
    echo ""
    echo "=== Estado del servicio ==="
    systemctl --user status mpd.service --no-pager
    echo ""
    echo "Para ver logs en tiempo real:"
    echo "  journalctl --user -u mpd.service -f"
    exit 1
fi

if command -v loginctl &>/dev/null; then
    if sudo -n loginctl enable-linger "${USER}" 2>/dev/null; then
        echo "[OK] Linger habilitado — MPD arrancará en el boot"
    else
        echo "[WARNING] No se pudo habilitar linger (requiere sudo)."
        echo "  Para habilitarlo manualmente: sudo loginctl enable-linger ${USER}"
    fi
fi

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Comandos útiles:"
echo "  rmpc                          — Iniciar cliente"
echo "  systemctl --user status mpd   — Estado de MPD"
echo "  systemctl --user restart mpd  — Reiniciar MPD"
echo "  systemctl --user stop mpd     — Detener MPD"
echo "  journalctl --user -u mpd -f   — Logs en tiempo real"
echo "  mpc update                    — Actualizar base de datos"
echo "  mpc ls                        — Listar canciones"
START_BLOCK

chmod +x "${SETUP_SCRIPT}"
echo "[OK] rmpc-setup generado: ${SETUP_SCRIPT}"
