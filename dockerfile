FROM fedora:43

ARG REPO_URL=https://github.com/mierak/rmpc.git
ARG BRANCH=master

RUN dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    && dnf install -y rust cargo git rpm-build rpmdevtools openssl-devel gcc make \
    && dnf clean all \
    && cargo install cargo-rpm

WORKDIR /build
RUN git clone --branch ${BRANCH} --depth 1 ${REPO_URL} app

WORKDIR /build/app
COPY rmpc-build/ rmpc-build/
RUN find rmpc-build -type f -exec chmod +x {} \;

VOLUME ["/output"]


CMD ["bash", "-c", "/build/app/rmpc-build/build-rpm.sh"]
