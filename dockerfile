FROM fedora:43

ARG REPO_URL=https://github.com/mierak/rmpc.git
ARG BRANCH=master

RUN dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    && dnf install -y rust cargo git rpm-build rpmdevtools openssl-devel gcc make \
    && dnf clean all \
    && cargo install cargo-rpm

WORKDIR /build
RUN git clone --branch ${BRANCH} ${REPO_URL} app
COPY build_rpm.sh /build/app/build_rpm.sh

WORKDIR /build/app

RUN chmod +x build_rpm.sh

VOLUME ["/output"]

CMD ["bash", "-c", "/build/app/build_rpm.sh"]
