# Reemplaza los siguientes placeholders en tiempo de ejecución (rmpc-setup):
#   {{MUSIC_DIR}}    → $HOME/Music
#   {{MPD_CONF_DIR}} → $HOME/.config/mpd
#   {{MPD_FIFO}}     → /run/user/<UID>/mpd.fifo

music_directory    "{{MUSIC_DIR}}"
playlist_directory "{{MPD_CONF_DIR}}/playlists"
db_file            "{{MPD_CONF_DIR}}/database"
log_file           "{{MPD_CONF_DIR}}/log"
pid_file           "{{MPD_CONF_DIR}}/pid"
state_file         "{{MPD_CONF_DIR}}/state"
sticker_file       "{{MPD_CONF_DIR}}/sticker.sql"

auto_update        "yes"
bind_to_address    "127.0.0.1" 
port               "6600"

audio_output {
    type           "pipewire"
    name           "PipeWire Sound Server"
}

audio_output {
    type           "fifo"
    name           "my_fifo"
    path           "{{MPD_FIFO}}"
    format         "44100:16:2"
}

filesystem_charset "UTF-8"
