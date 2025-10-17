# 🎵 RMPC - RPM Package Builder

Automated RPM package builder for [rmpc](https://github.com/mierak/rmpc) (Rust Music Player Client) with Docker support.

## 🚀 Quick Start

### Prerequisites

- Docker installed and running
- `sudo` privileges (for Docker operations)

### Install the Package

```bash
# Install the RPM package
sudo dnf install ./rmpc-*.rpm

# Run the setup script to configure MPD for your user
rmpc-setup

# Launch rmpc
rmpc
```

## 📦 Build Methods

### Method 1: Custom Spec Build (Default)

**Features:**

- ✅ Includes MPD (>= 0.23.5) as a dependency
- ✅ Automatic MPD configuration with `rmpc-setup` script
- ✅ Full RPM metadata and post-installation hooks
- ✅ PipeWire audio output configuration
- ✅ Systemd user service integration

**Build:**

```bash
# Clean Docker environment (optional but recommended)
docker system prune -a --volumes -f

# Build the Docker image
docker build -t rmpc-rpm .

# Extract the generated RPM package
docker run --rm -v $(pwd):/output rmpc-rpm
```

### Method 2: Generic Build (cargo-rpm)

A simpler method using `cargo-rpm` for minimal RPM generation.

**Build:**

```bash
docker build -f generico-cargo -t rpm-builder \
  --build-arg REPO_URL=https://github.com/mierak/rmpc.git \
  --build-arg BRANCH=master \
  .
docker run --rm -v $(pwd):/final rpm-builder
```

## 🛠️ What's Included

### rmpc-setup Script

The package includes a setup script that configures:

- Music directory (`~/Music`)
- MPD configuration file (`~/.config/mpd/mpd.conf`)
- MPD database and playlist directories
- PipeWire audio output
- Systemd user service

Run after installation:

```bash
rmpc-setup
```

### MPD Configuration

Default configuration includes:

- Music directory: `~/Music`
- Bind address: `127.0.0.1:6600`
- Audio output: PipeWire
- Auto-update: enabled

## 📁 Project Structure

```
.
├── dockerfile             # Main Dockerfile (custom spec method)
├── generico-cargo         # Dockerfile for cargo-rpm method
├── build_rpm.sh           # RPM build script with spec generation
└── Readme.md              # This file
```

## 🔧 Customization

### Build from Different Branch or Fork

```bash
sudo docker build -t rmpc-rpm \
  --build-arg REPO_URL=https://github.com/YOUR_FORK/rmpc.git \
  --build-arg BRANCH=your-branch \
  .
```

### Modify Build Script

Edit `build_rpm.sh` to customize:

- RPM metadata (version, release, packager info)
- Dependencies
- Installation paths
- Post-installation scripts

## 📝 Notes

- Built and tested on Fedora Linux
- Requires RPM Fusion repositories for some dependencies
- Uses Rust stable toolchain
- Default maintainer: Sassech <lainstroop@gmail.com>

## 🐛 Troubleshooting

### MPD won't start

```bash
# Check MPD status
systemctl --user status mpd

# View logs
journalctl --user -u mpd -f
```

### No audio output

```bash
# Verify PipeWire is running
systemctl --user status pipewire

# Check audio devices
pactl list sinks
```

## 📚 Resources

- [rmpc GitHub Repository](https://github.com/mierak/rmpc)
- [MPD Documentation](https://www.musicpd.org/doc/html/)
- [Fedora RPM Packaging Guide](https://docs.fedoraproject.org/en-US/packaging-guidelines/)
