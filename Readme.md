# 🎵 RMPC RPM Builder for Fedora

Automated CI/CD pipeline for building [rmpc](https://github.com/mierak/rmpc) (Rust Music Player Client) RPM packages using GitHub Actions and Podman.

## 📦 Installation

### From Releases (Recommended)

Download the latest RPM from [Releases](https://github.com/Sassech/RMPCFedora/releases):

```bash
# Install the package
sudo dnf install ./rmpc-*.rpm

# Configure MPD for your user
rmpc-setup

# Launch rmpc
rmpc
```

## 🤖 CI/CD Pipeline

This repository features automated monthly builds:

- **Version Check**: Runs on day 1 of each month at 00:00 UTC
- **Build & Release**: Runs at 02:00 UTC if new version detected
- **Manual Trigger**: Available via GitHub Actions workflow dispatch

### Workflows

1. **check-new-version.yml**: Monitors upstream rmpc releases
2. **build-release.yml**: Builds RPM with Podman and creates GitHub release

## 🛠️ Manual Build

### With Podman (Recommended)

```bash
# Build container image
podman build -t rmpc-builder .

# Run and extract RPM
mkdir -p output
podman run --rm -v $(pwd)/output:/output:Z rmpc-builder
```

### With Docker

```bash
# Build and extract
docker build -t rmpc-rpm .
docker run --rm -v $(pwd)/output:/output rmpc-rpm
```

### Custom Build

```bash
# Build from specific branch or fork
podman build -t rmpc-builder \
  --build-arg REPO_URL=https://github.com/YOUR_FORK/rmpc.git \
  --build-arg BRANCH=your-branch \
  .
```

## ✨ Features

- **MPD Integration**: Includes MPD (>= 0.23) as dependency
- **Automated Setup**: `rmpc-setup` script configures everything
- **PipeWire Support**: Pre-configured audio output
- **FIFO Support**: Ready for visualizers (Cava)
- **Systemd Service**: MPD runs as user service
- **Custom Config**: Pre-configured rmpc settings

### What rmpc-setup Does

- Creates music directory (`~/Music`)
- Generates MPD configuration
- Sets up PipeWire audio output
- Creates FIFO for visualizers
- Configures systemd user service
- Starts MPD automatically

## 📁 Project Structure

```
.
├── .github/workflows/     # CI/CD automation
├── dockerfile             # Podman/Docker build
├── build_rpm.sh          # RPM build script
├── generico-cargo        # Alternative cargo-rpm build
└── Readme.md
```

## 🐛 Troubleshooting

**MPD not starting:**

```bash
systemctl --user status mpd
journalctl --user -u mpd -f
```

**No audio:**

```bash
systemctl --user status pipewire
pactl list sinks
```

**Update music database:**

```bash
mpc update
mpc ls
```

## 📚 Resources

- [rmpc upstream](https://github.com/mierak/rmpc)
- [MPD Documentation](https://www.musicpd.org/doc/html/)

---

**Maintainer:** Sassech <<lainstroop@gmail.com>>  
**Based on:** [rmpc by mierak](https://github.com/mierak/rmpc)
