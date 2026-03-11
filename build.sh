#!/bin/sh
#
# build.sh - Build and install byobu on OpenBSD with patches applied
#
# Usage:
#   ./build.sh                  # download, patch, build, install to /usr/local
#   ./build.sh --prefix=/opt    # install to custom prefix
#   ./build.sh --patch-only     # download and apply patches without building
#

set -e

BYOBU_VERSION="6.14"
BYOBU_URL="https://github.com/dustinkirkland/byobu/archive/refs/tags/${BYOBU_VERSION}.tar.gz"
PREFIX="/usr/local"
PATCH_ONLY=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/_build"

usage() {
	printf "Usage: %s [--prefix=DIR] [--patch-only] [--help]\n" "$(basename "$0")"
	printf "\nOptions:\n"
	printf "  --prefix=DIR    Install prefix (default: /usr/local)\n"
	printf "  --patch-only    Download and apply patches without building\n"
	printf "  --help          Show this help\n"
	exit 0
}

for arg in "$@"; do
	case "$arg" in
		--prefix=*) PREFIX="${arg#--prefix=}" ;;
		--patch-only) PATCH_ONLY=1 ;;
		--help) usage ;;
		*) printf "Unknown option: %s\n" "$arg"; usage ;;
	esac
done

# --- Pre-flight checks ---

if [ "$(uname -s)" != "OpenBSD" ]; then
	printf "WARNING: This build script is designed for OpenBSD.\n"
	printf "Detected OS: %s\n" "$(uname -s)"
	printf "Continue anyway? [y/N] "
	read ans
	case "$ans" in
		[Yy]*) ;;
		*) exit 1 ;;
	esac
fi

for cmd in curl tar patch autoconf automake make; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		printf "ERROR: Required tool '%s' not found.\n" "$cmd"
		case "$cmd" in
			autoconf) printf "  Install: pkg_add autoconf\n" ;;
			automake) printf "  Install: pkg_add automake\n" ;;
			*) printf "  Install: pkg_add %s\n" "$cmd" ;;
		esac
		exit 1
	fi
done

# Check for bash and tmux (runtime dependencies)
for cmd in bash tmux; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		printf "WARNING: Runtime dependency '%s' not found. Install: pkg_add %s\n" "$cmd" "$cmd"
	fi
done

# --- Download ---

printf "==> Downloading byobu %s...\n" "$BYOBU_VERSION"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

curl -sL "$BYOBU_URL" -o "byobu-${BYOBU_VERSION}.tar.gz"
tar xzf "byobu-${BYOBU_VERSION}.tar.gz"
cd "byobu-${BYOBU_VERSION}"

# --- Apply patches ---

printf "==> Applying OpenBSD patches...\n"
for p in "$SCRIPT_DIR"/patches/patch-*; do
	[ -f "$p" ] || continue
	pname="$(basename "$p")"
	printf "    Applying %s\n" "$pname"
	patch -p1 -N < "$p" || {
		printf "    WARNING: Patch %s did not apply cleanly (may already be applied)\n" "$pname"
	}
done

if [ "$PATCH_ONLY" = "1" ]; then
	printf "==> Patches applied. Source is in: %s/byobu-%s\n" "$WORK_DIR" "$BYOBU_VERSION"
	exit 0
fi

# --- Build ---

printf "==> Running autoreconf...\n"
# OpenBSD requires explicit autoconf/automake versions
AUTOCONF_VERSION="${AUTOCONF_VERSION:-2.71}"
AUTOMAKE_VERSION="${AUTOMAKE_VERSION:-1.16}"
export AUTOCONF_VERSION AUTOMAKE_VERSION
autoreconf -fi

printf "==> Configuring with prefix=%s...\n" "$PREFIX"
./configure --prefix="$PREFIX"

printf "==> Building...\n"
make

# --- Install ---

printf "==> Installing to %s (may require root)...\n" "$PREFIX"
if [ "$(id -u)" = "0" ]; then
	make install
else
	printf "    Running make install with doas...\n"
	doas make install
fi

printf "==> Done. byobu %s installed to %s\n" "$BYOBU_VERSION" "$PREFIX"
printf "\nPost-install notes:\n"
printf "  - Ensure bash is installed: pkg_add bash\n"
printf "  - Ensure tmux is installed: pkg_add tmux\n"
printf "  - Run 'byobu' to start\n"
printf "  - Some status indicators (disk_io, entropy) are not available on OpenBSD\n"
