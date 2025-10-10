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
# Script to set up MPD and rmpc for the user

echo "=== Setting up MPD and rmpc for $USER ==="

# Create music directory
MUSIC_DIR="$HOME/Music"
mkdir -p "$MUSIC_DIR"
mkdir -p "$HOME/.config/mpd/playlists"
echo "✓ Music directory: $MUSIC_DIR"

# Create necessary directories for MPD
mkdir -p "$HOME/.config/mpd/playlists"

# Configure MPD if it doesn't exist
if [ ! -f "$HOME/.config/mpd/mpd.conf" ]; then
    cat > "$HOME/.config/mpd/mpd.conf" <<CONF
music_directory    "$MUSIC_DIR"
playlist_directory "$HOME/.config/mpd/playlists"
db_file            "$HOME/.config/mpd/database"
log_file           "$HOME/.config/mpd/log"
pid_file           "$HOME/.config/mpd/pid"
state_file         "$HOME/.config/mpd/state"
sticker_file       "$HOME/.config/mpd/sticker.sql"

# Actualización automática
auto_update        "yes"
bind_to_address "127.0.0.1"
# bind_to_address    "/tmp/mpd_socket"
# puerto TCP deshabilitado para evitar conflictos
port            "6600"

# Salidas de audio
audio_output {
    type            "pipewire"            # para audio normal
    name            "PipeWire Sound Server"
}

audio_output {
    type            "fifo"                # para Cava
    name            "my_fifo"
    path            "/run/user/1000/mpd.fifo"  # ruta absoluta del usuario
    format          "44100:16:2"
}

# 🔒 Permisos
filesystem_charset  "UTF-8"
CONF
    echo "✓ MPD configuration created"
else
    echo "✓ MPD configuration already exists"
fi

# Create configuration directory for rmpc
mkdir -p "$HOME/.config/rmpc"

# Create rmpc configuration if it doesn't exist
if [ ! -f "$HOME/.config/rmpc/config.ron" ]; then
    # Write provided custom RON configuration
    cat > "$HOME/.config/rmpc/config.ron" <<'RMPCCONF'
#![enable(implicit_some)]
#![enable(unwrap_newtypes)]
#![enable(unwrap_variant_newtypes)]
(

// 🔹 Conexión a MPD usando FIFO
mpd: (
    method: "fifo",
    path: "/run/user/1000/mpd.fifo", // debe coincidir con MPD
),

    // 🔍 Configuración de interfaz
    show_album_art: true,
    enable_cava: true,

    // ⚡ Comportamiento
    auto_refresh: true,
    update_interval: 5,

// 🔹 Directorios y cache
cache_dir: Some("/tmp/rmpc/cache"), // donde RMPC guarda archivos temporales
lyrics_dir: Some("~/Music"),         // carpeta raíz de letras
password: None,
theme: "catppuccin_mocha",


// 🔹 Notificaciones y volumen
on_song_change: ["~/.config/rmpc/notify"], 
volume_step: 5,
max_fps: 30,
scrolloff: 0,
wrap_navigation: false,
enable_mouse: true,
status_update_interval_ms: 1000,
select_current_song_on_change: false,
browser_column_widths: [20, 38, 42],

// 🔹 Configuración de album art
album_art: (
    method: Auto,
    max_size_px: (width: 900, height: 900),
    disabled_protocols: ["http://", "https://"],
    vertical_align: Top,
    horizontal_align: Center,
),

cava: (
    framerate: 60, // default 60
    autosens: true, // default true
    sensitivity: 100, // default 100
    lower_cutoff_freq: 50, // not passed to cava if not provided
    higher_cutoff_freq: 10000, // not passed to cava if not provided
    input: (
        method: Fifo,
        source: "/run/user/1000/mpd.fifo",
        sample_rate: 44100,
        channels: 2,
        sample_bits: 16,
    ),
    smoothing: (
        noise_reduction: 77, // default 77
        monstercat: false, // default false
        waves: false, // default false
    ),
    // this is a list of floating point numbers thats directly passed to cava
    // they are passed in order that they are defined
    eq: [],// ecualizador, vacío si no se usa
),

// 🔹 Keybinds generales
    keybinds: (
        global: {
            ":":       CommandMode,
            ",":       VolumeDown,
            "s":       Stop,
            ".":       VolumeUp,
            "<Tab>":   NextTab,
            "<S-Tab>": PreviousTab,
            "1":       SwitchToTab("Lyrics"),
            "2":       SwitchToTab("Queue"),
    	    "3":       SwitchToTab("Directories"),
            "4":       SwitchToTab("Artists"),
            "5":       SwitchToTab("Albums"),
            "6":       SwitchToTab("Search"),
            "q":       Quit,
            ">":       NextTrack,
            "p":       TogglePause,
            "<":       PreviousTrack,
            "f":       SeekForward,
            "z":       ToggleRepeat,
            "x":       ToggleRandom,
            "c":       ToggleConsume,
            "v":       ToggleSingle,
            "b":       SeekBack,
            "|":       ShowHelp,
            "I":       ShowCurrentSongInfo,
            "O":       ShowOutputs,
            "P":       ShowDecoders,
        },

        // navegación por listas y splits
        navigation: {
            "k":         Up,
            "j":         Down,
            "h":         Left,
            "l":         Right,
            "<Up>":      Up,
            "<Down>":    Down,
            "<Left>":    Left,
            "<Right>":   Right,
            "<C-k>":     PaneUp,
            "<C-j>":     PaneDown,
            "<C-h>":     PaneLeft,
            "<C-l>":     PaneRight,
            "<C-u>":     UpHalf,
            "N":         PreviousResult,
            "a":         Add,
            "A":         AddAll,
            "r":         Rename,
            "n":         NextResult,
            "g":         Top,
            "<Space>":   Select,
            "<C-Space>": InvertSelection,
            "G":         Bottom,
            "<CR>":      Confirm,
            "i":         FocusInput,
            "J":         MoveDown,
            "<C-d>":     DownHalf,
            "/":         EnterSearch,
            "<C-c>":     Close,
            "<Esc>":     Close,
            "K":         MoveUp,
            "D":         Delete,
        },
        // atajos dentro de la cola de reproducción
        queue: {
            "D":       DeleteAll,
            "<CR>":    Play,
            "<C-s>":   Save,
            "a":       AddToPlaylist,
            "d":       Delete,
            "i":       ShowInfo,
            "C":       JumpToCurrent,
        },
    ),
// 🔹 Configuración de búsqueda
    search: (
        case_sensitive: false,
        mode: Contains,
        tags: [
            (value: "any",         label: "Any Tag"),
            (value: "artist",      label: "Artist"),
            (value: "album",       label: "Album"),
            (value: "title",       label: "Title"),
            (value: "filename",    label: "Filename"),
            (value: "genre",       label: "Genre"),
            (value: "albumartist", label: "Featured"),
        ],
    ),

// 🔹 Configuración de artistas
artists: (
    album_display_mode: SplitByDate, // cómo se agrupan los álbumes
    album_sort_by: Date,             // cómo se ordenan
),
// 🔹 Pestañas principales (tabs)
tabs: [
    (
        name: "Lyrics", // pestaña de letras
        pane: Split(
            direction: Vertical,
            panes: [
                (size: "25%", pane: Pane(AlbumArt)), 
                (size: "70%", pane: Pane(Lyrics), vertical_align: Bottom)
            ],
        ),
    ),
    (
        name: "Queue", // cola de reproducción
        pane: Split(
            direction: Horizontal,
            panes: [
            // 🔹 Columna izquierda: AlbumArt y Lyrics
            (size: "40%", pane: Split(
                direction: Vertical,
                panes: [
                    (size: "60%", pane: Pane(AlbumArt)), // arriba: portada
                    (size: "40%", pane: Pane(Lyrics)),   // abajo: letras
                ],
            )),
            // 🔹 Columna derecha: Queue y Cava
                (size: "60%", pane: Split(
                    direction: Vertical,
                    panes: [
                        (size: "30%", pane: Pane(Queue)),  // arriba: cola
                        (size: "70%", pane: Pane(Cava)),  // abajo: visualizador
                    ],
                )),
            ],
        ),
    ),
    (
        name: "Directories", // explorador de carpetas
        pane: Pane(Directories),
    ),
    ( 
        name: "Artists", // vista de artistas
        pane: Pane(Artists),
    ),
    (
        name: "Albums", // vista de álbumes
        pane: Pane(Albums),
    ),
    (
        name: "Search", // buscador
        pane: Pane(Search),
    ),
]
)
RMPCCONF
    echo "✓ Configuración de rmpc creada"
else
    echo "✓ Configuración de rmpc ya existe"
fi

# Create systemd user service for MPD
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
echo "✓ Systemd user service created"

# Stop any running MPD instances
pkill -u "$USER" mpd 2>/dev/null || true
sleep 1

# Reload systemd user daemon
systemctl --user daemon-reload
echo "✓ Systemd reloaded"

# Enable MPD to start automatically
systemctl --user enable mpd.service
echo "✓ MPD enabled for automatic start"

# Start MPD
systemctl --user start mpd.service
echo "✓ Trying to start MPD..."

# Wait a moment for MPD to start
sleep 2

# Check the status of MPD
if systemctl --user is-active --quiet mpd.service; then
    echo "✓ MPD is running correctly"
else
    echo "✗ MPD failed to start. Checking the error..."
    echo ""
    echo "=== MPD Log ==="
    if [ -f "$HOME/.config/mpd/log" ]; then
        tail -20 "$HOME/.config/mpd/log"
    else
        journalctl --user -u mpd.service -n 20 --no-pager
    fi
    echo ""
    echo "=== Status Service ==="
    systemctl --user status mpd.service --no-pager
    echo ""
    echo "Exec for logs:"
    echo "  journalctl --user -u mpd.service -f"
    exit 1
fi

# Enable linger for MPD to start at boot
if command -v loginctl &> /dev/null; then
    if sudo -n loginctl enable-linger "$USER" 2>/dev/null; then
        echo "✓ MPD will start automatically at boot"
    else
        echo "⚠ Could not enable linger (requires sudo). MPD will only start on login."
        echo "  To enable it manually: sudo loginctl enable-linger $USER"
    fi
fi

echo ""
echo "=== Configuration completed ==="
echo "You can run 'rmpc' to start the MPD client"
echo ""
echo "Useful commands:"
echo "  systemctl --user status mpd     - Check MPD status"
echo "  systemctl --user restart mpd    - Restart MPD"
echo "  systemctl --user stop mpd       - Stop MPD"
echo "  journalctl --user -u mpd -f     - View logs in real time"
echo "  mpc update                      - Update music database"
echo "  mpc ls                          - List songs in the database"
echo "  rmpc                            - Start rmpc"
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
# Music Player Daemon
Requires:       mpd
# Command line client for MPD
Requires:       mpc

%description
rmpc is a fast and modern MPD client for the terminal, inspired by ncmpcpp.
This package includes rmpc and a setup script to configure MPD as a user service.

%install
# Install main binary
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{_sourcedir}/rmpc-0.10.0/target/release/rmpc %{buildroot}/usr/bin/rmpc

# Install setup script
install -m 0755 %{_sourcedir}/rmpc-0.10.0/rmpc-setup %{buildroot}/usr/bin/rmpc-setup

%files
/usr/bin/rmpc
/usr/bin/rmpc-setup

%post
cat <<MESSAGE

╔════════════════════════════════════════════════════════════╗
║        rmpc installed successfully                          ║
╚════════════════════════════════════════════════════════════╝

To set up MPD for your user, run:

    rmpc-setup

This will configure MPD as a user service and create the
necessary configuration directories and files.

After that, you can run 'rmpc' to use the client.

MESSAGE

%postun
if [ \$1 -eq 0 ]; then
    cat <<MESSAGE

rmpc has been uninstalled.

If you want to remove the MPD configuration, run:
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