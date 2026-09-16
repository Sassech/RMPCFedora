#!/bin/bash
set -e

export RPMBUILD_ROOT="${RPMBUILD_ROOT:-/root/rpmbuild}"
export PKG_VERSION="${PKG_VERSION}"
export PKG_NAME="rmpc"
export SOURCE_DIR="${RPMBUILD_ROOT}/SOURCES/${PKG_NAME}-${PKG_VERSION}"
export OUTPUT_DIR="${OUTPUT_DIR:-/output}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Building ${PKG_NAME}-${PKG_VERSION} ==="
echo "    Output : ${OUTPUT_DIR}"

rpmdev-setuptree --tree="${RPMBUILD_ROOT}"
mkdir -p "${SOURCE_DIR}"
# `.` (not `./*`) so hidden entries like `.git` are copied too — the
# upstream build.rs embeds commit info via vergen-gitcl at compile time.
cp -r . "${SOURCE_DIR}/"

bash "${SCRIPT_DIR}/build-binary.sh"
bash "${SCRIPT_DIR}/generate-setup.sh"
bash "${SCRIPT_DIR}/generate-spec.sh"

mkdir -p "${OUTPUT_DIR}"
cp "${RPMBUILD_ROOT}/RPMS/x86_64/"*.rpm "${OUTPUT_DIR}/"

echo ""
echo "=== RPM Generated in ${OUTPUT_DIR} ==="
ls -lh "${OUTPUT_DIR}/"*.rpm
