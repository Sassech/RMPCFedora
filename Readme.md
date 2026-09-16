# RMPC RPM Builder for Fedora

Empaqueta [rmpc](https://github.com/mierak/rmpc) como RPM para Fedora, incluyendo un script de configuración automática de MPD como servicio de usuario.

## Instalación

### Desde Releases (Recomendado)

Descarga el último RPM desde [Releases](https://github.com/Sassech/RMPCFedora/releases):

```bash
sudo dnf install ./rmpc-*.rpm
rmpc-setup
rmpc
```

## Build Manual

### Con Podman (Recomendado)

```bash
podman build -t rmpc-builder .

mkdir -p output
podman run --rm -v $(pwd)/output:/output:Z rmpc-builder
```

### Con Docker

```bash
docker build -t rmpc-builder .

mkdir -p output
docker run --rm -v $(pwd)/output:/output rmpc-builder
```

### Variables de entorno

Puedes personalizar el build sin modificar el código:

```bash
podman run --rm \
  -v $(pwd)/output:/output:Z \
  -e PKG_VERSION=0.10.0 \
  -e OUTPUT_DIR=/output \
  rmpc-builder
```

| Variable       | Default          | Descripción                     |
|----------------|------------------|---------------------------------|
| `PKG_VERSION`  | `0.10.0`         | Versión del paquete             |
| `RPMBUILD_ROOT`| `/root/rpmbuild` | Directorio de trabajo de rpmbuild |
| `OUTPUT_DIR`   | `/output`        | Destino del RPM generado        |

## Estructura del Proyecto

```
.
├── dockerfile
├── rmpc-build/
│   ├── build-rpm.sh             # Entrada: orquesta todo y define variables
│   ├── build-binary.sh          # Compila el binario con cargo
│   ├── generate-setup.sh        # Genera el script rmpc-setup instalable
│   ├── generate-spec.sh         # Genera el .spec y ejecuta rpmbuild
│   └── config/
│       ├── mpd.conf.tpl         # Template de configuración de MPD
│       └── rmpc.config.ron.tpl  # Template de configuración de rmpc
├── .github/workflows/           # CI/CD
└── README.md
```

Los archivos `.tpl` usan `{{placeholders}}` que `rmpc-setup` resuelve con los
valores reales del usuario en el momento de la instalación (`$HOME`, UID, etc.).
Para cambiar la configuración por defecto de MPD o rmpc, edita esos archivos.

## Qué hace rmpc-setup

Al ejecutar `rmpc-setup` después de instalar el RPM, el script:

- Crea `~/Music` y los directorios de configuración necesarios
- Genera `~/.config/mpd/mpd.conf` desde el template con tus rutas reales
- Genera `~/.config/rmpc/config.ron` desde el template
- Instala y habilita MPD como servicio systemd de usuario
- Inicia MPD automáticamente

## Troubleshooting

**MPD no arranca:**
```bash
systemctl --user status mpd
journalctl --user -u mpd -f
```

**Sin audio:**
```bash
systemctl --user status pipewire
pactl list sinks
```

**Actualizar base de datos de música:**
```bash
mpc update
mpc ls
```

## Recursos

- [rmpc upstream](https://github.com/mierak/rmpc)
- [MPD Documentation](https://www.musicpd.org/doc/html/)

---

Basado en [rmpc by mierak](https://github.com/mierak/rmpc)