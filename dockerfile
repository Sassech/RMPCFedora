FROM fedora:latest

ARG REPO_URL=https://github.com/mierak/rmpc.git
ARG BRANCH=master

# Agregar repositorio RPM Fusion para dependencias adicionales
RUN dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Instalar dependencias
RUN dnf install -y rust cargo git rpm-build rpmdevtools openssl-devel gcc make \
    && dnf clean all

# Instalar cargo-rpm
RUN cargo install cargo-rpm

# Copiar proyecto y script
WORKDIR /build
RUN git clone --branch ${BRANCH} ${REPO_URL} app
COPY build_rpm.sh /build/app/build_rpm.sh

WORKDIR /build/app

# Dar permisos de ejecución al script
RUN chmod +x build_rpm.sh

# Ejecutar script
# RUN ./build_rpm.sh

# Carpeta compartida para extraer el RPM
VOLUME ["/output"]

# Agrega al final:
CMD ["bash", "-c", "/build/app/build_rpm.sh"]
