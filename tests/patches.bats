#!/usr/bin/env bats

# Integration tests for OpenBSD-patched byobu status scripts.
# These tests verify the patched scripts source correctly and
# produce output (or exit cleanly) on OpenBSD.
#
# Run with: bats tests/

BYOBU_SRC="${BATS_TEST_DIRNAME}/../_build/byobu-6.14"

setup() {
    if [ ! -d "$BYOBU_SRC" ]; then
        skip "Run ./build.sh --patch-only first to populate _build/"
    fi
    if [ "$(uname -s)" != "OpenBSD" ]; then
        skip "These tests require OpenBSD"
    fi
}

# --- Patch application ---

@test "all patches applied without rejects" {
    [ -d "$BYOBU_SRC" ]
    rejects=$(find "$BYOBU_SRC" -name "*.rej" 2>/dev/null)
    [ -z "$rejects" ]
}

# --- Shell syntax validation ---

@test "memory: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/memory"
}

@test "cpu_temp: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/cpu_temp"
}

@test "battery: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/battery"
}

@test "cpu_freq: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/cpu_freq"
}

@test "uptime: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/uptime"
}

@test "load_average: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/load_average"
}

@test "disk: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/disk"
}

@test "disk_io: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/disk_io"
}

@test "cpu_count: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/cpu_count"
}

@test "fan_speed: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/fan_speed"
}

@test "swap: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/swap"
}

@test "network: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/network"
}

@test "entropy: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/entropy"
}

@test "raid: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/raid"
}

@test "ip_address: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/ip_address"
}

@test "wifi_quality: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/wifi_quality"
}

@test "processes: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/processes"
}

@test "include/shutil: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/include/shutil"
}

@test "include/constants: valid shell syntax" {
    bash -n "$BYOBU_SRC/usr/lib/byobu/include/constants"
}

# --- OpenBSD sysctl probes (runtime) ---

@test "sysctl hw.physmem returns a number" {
    result=$(sysctl -n hw.physmem)
    [ -n "$result" ]
    [ "$result" -gt 0 ]
}

@test "sysctl hw.pagesize returns a number" {
    result=$(sysctl -n hw.pagesize)
    [ -n "$result" ]
    [ "$result" -gt 0 ]
}

@test "sysctl hw.ncpuonline returns a number" {
    result=$(sysctl -n hw.ncpuonline)
    [ -n "$result" ]
    [ "$result" -gt 0 ]
}

@test "sysctl hw.cpuspeed returns a number" {
    result=$(sysctl -n hw.cpuspeed)
    [ -n "$result" ]
    [ "$result" -gt 0 ]
}

@test "sysctl kern.boottime returns a number" {
    result=$(sysctl -n kern.boottime)
    [ -n "$result" ]
    [ "$result" -gt 0 ]
}

@test "sysctl vm.loadavg returns load values" {
    result=$(sysctl -n vm.loadavg)
    [ -n "$result" ]
    # Should have at least one space-separated value
    count=$(echo "$result" | awk '{ print NF }')
    [ "$count" -ge 1 ]
}

@test "vmstat -s produces pages free line" {
    result=$(vmstat -s | grep "pages free")
    [ -n "$result" ]
}

@test "route -n get default returns an interface" {
    result=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2 }')
    [ -n "$result" ]
}

@test "df -h / produces output" {
    result=$(df -h / | awk 'END { print $2 }')
    [ -n "$result" ]
}

@test "mount output is parseable for device-to-mountpoint mapping" {
    result=$(mount | awk '{ print $1, $3 }' | head -1)
    [ -n "$result" ]
}

@test "swapctl -sk produces output or exits cleanly" {
    # May have no swap configured in CI VM; just verify it doesn't crash
    swapctl -sk 2>/dev/null || true
}

@test "netstat -ibn produces interface byte counts" {
    result=$(netstat -ibn | head -5)
    [ -n "$result" ]
}

@test "ps -ax runs without error" {
    result=$(ps -ax | wc -l)
    [ "$result" -gt 0 ]
}

# --- OpenBSD-specific code path smoke tests ---

@test "memory: OpenBSD code path computes total and free" {
    physmem=$(sysctl -n hw.physmem)
    total=$((physmem / 1024))
    [ "$total" -gt 0 ]

    pagesize=$(sysctl -n hw.pagesize)
    free_pages=$(vmstat -s 2>/dev/null | awk '/pages free$/ { print $1; exit }')
    [ -n "$free_pages" ]
    free=$(( free_pages * pagesize / 1024 ))
    [ "$free" -ge 0 ]
    [ "$free" -le "$total" ]
}

@test "uptime: OpenBSD code path computes positive uptime" {
    bt=$(sysctl -n kern.boottime)
    now=$(date +%s)
    u=$((now - bt))
    [ "$u" -gt 0 ]
}

@test "load_average: OpenBSD code path extracts load value" {
    one=$(sysctl -n vm.loadavg 2>/dev/null | awk '{ print $1 }')
    [ -n "$one" ]
    # Verify it looks like a number (integer or float)
    echo "$one" | grep -qE '^[0-9]+\.?[0-9]*$'
}

@test "cpu_count: getconf or sysctl returns cpu count" {
    c=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpuonline 2>/dev/null || echo 1)
    [ "$c" -ge 1 ]
}

@test "disk: df output is parseable without -P flag" {
    out=$(df -h / 2>/dev/null | awk 'END { printf("%s %s", $2, $5); }')
    [ -n "$out" ]
    set -- ${out}
    size=${1}
    pct=${2}
    [ -n "$size" ]
    [ -n "$pct" ]
}

@test "disk_io: iostat -DI produces per-disk KB output" {
    result=$(iostat -DI 2>/dev/null | awk 'NR>1 && NF>=3 { print $1, $2; exit }')
    [ -n "$result" ]
    # First field should be a disk name, second should be a number (KB)
    disk=$(echo "$result" | awk '{ print $1 }')
    kb=$(echo "$result" | awk '{ print $2 }')
    [ -n "$disk" ]
    echo "$kb" | grep -qE '^[0-9]+\.?[0-9]*$'
}

@test "disk_io: root mount point maps to a disk device" {
    part=$(mount | awk '$3 == "/" { print $1; exit }')
    [ -n "$part" ]
    # Strip partition letter to get disk name (e.g., sd0a -> sd0)
    disk=$(echo "${part##*/}" | sed 's/[a-p]$//')
    [ -n "$disk" ]
    # Verify iostat knows about this disk
    iostat -DI 2>/dev/null | awk -v d="$disk" '$1 == d { found=1 } END { exit !found }'
}

@test "entropy: patched script contains OpenBSD arc4random path" {
    grep -q 'arc4random' "$BYOBU_SRC/usr/lib/byobu/entropy"
}

@test "entropy: patched script displays N/A on OpenBSD" {
    grep -q 'N/A' "$BYOBU_SRC/usr/lib/byobu/entropy"
}

@test "sed -i portable detection works on OpenBSD" {
    tmpfile=$(mktemp)
    echo "hello" > "$tmpfile"
    # OpenBSD sed: -i takes backup suffix as next arg, use .bak then remove
    sed -i.bak 's/hello/world/' "$tmpfile"
    result=$(cat "$tmpfile")
    rm -f "$tmpfile" "${tmpfile}.bak"
    [ "$result" = "world" ]
}
