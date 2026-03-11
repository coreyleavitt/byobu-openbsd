# byobu-openbsd

OpenBSD port and patches for [byobu](https://www.byobu.org/) terminal multiplexer (v6.14).

Byobu upstream is heavily Linux-centric. This project provides patches and a build system to make byobu work correctly on OpenBSD.

## Quick Start

```sh
# Install dependencies
pkg_add bash tmux autoconf automake curl

# Clone and build
git clone https://github.com/coreyleavitt/byobu-openbsd.git
cd byobu-openbsd
./build.sh
```

## What Gets Patched

| Component | Issue | Fix |
|-----------|-------|-----|
| `memory` | Reads `/proc/meminfo` | Uses `sysctl hw.physmem` + `vmstat -s` |
| `cpu_temp` | Reads `/sys/class/hwmon`, `/proc/acpi` | Uses `sysctl hw.sensors` |
| `battery` | Reads `/sys/class/power_supply`, `/proc/acpi/battery` | Uses `apm(8)` |
| `cpu_freq` | Reads `/sys/devices/system/cpu`, `/proc/cpuinfo` | Uses `sysctl hw.cpuspeed` |
| `uptime` | Reads `/proc/uptime` | Uses `sysctl kern.boottime` |
| `load_average` | Reads `/proc/loadavg` | Uses `sysctl vm.loadavg` |
| `disk` | Uses `df -P`, reads `/proc/mounts` | Drops `-P`, uses `mount(8)` output |
| `disk_io` | Reads `/sys/block/*/stat` | Uses `iostat -DI` for cumulative KB per disk |
| `cpu_count` | Reads `/proc/cpuinfo` | Uses `sysctl hw.ncpuonline` |
| `fan_speed` | Reads `/sys/class/hwmon` | Uses `sysctl hw.sensors` |
| `swap` | Reads `/proc/meminfo` | Uses `swapctl -sk` |
| `network` | Reads `/proc/net/dev` | Uses `netstat -ibn` |
| `entropy` | Reads `/proc/sys/kernel/random` | Displays "N/A" (OpenBSD uses arc4random) |
| `raid` | Reads `/proc/mdstat` | Detail uses `bioctl(8)` |
| `ip_address` | Reads `/proc/net/ipv6_route` | Uses `ifconfig(8)` |
| `wifi_quality` | Uses `iw`/`iwconfig` (Linux) | Uses `ifconfig(8)` signal data |
| `processes` | Uses `ps -ej` | Uses `ps -ax` |
| `sed -i` | GNU syntax throughout | Portable BSD `sed -i ''` detection |
| `/dev/shm` | Assumed present | Falls back to `~/.cache/byobu` |
| `get_now()` | Reads `/proc/uptime` | Uses `sysctl kern.boottime` |
| `get_network_interface()` | Reads `/proc/net/route` | Uses `route -n get default` |

## OpenBSD Notes

- **disk_io**: Uses `iostat -DI` for combined read+write throughput (Linux separates read/write via `/sys/block`).
- **entropy**: Displays "N/A" -- OpenBSD uses `arc4random(3)` which is always fully seeded; no pool metric exists.

## Project Structure

```
.
├── Makefile          # OpenBSD port Makefile
├── build.sh          # Standalone build script
├── distinfo          # Port checksums (placeholder)
├── patches/          # Unified diff patches (18 files)
│   ├── patch-usr_lib_byobu_battery
│   ├── patch-usr_lib_byobu_cpu_count
│   ├── patch-usr_lib_byobu_cpu_freq
│   ├── patch-usr_lib_byobu_cpu_temp
│   ├── patch-usr_lib_byobu_disk
│   ├── patch-usr_lib_byobu_disk_io
│   ├── patch-usr_lib_byobu_entropy
│   ├── patch-usr_lib_byobu_fan_speed
│   ├── patch-usr_lib_byobu_include_constants
│   ├── patch-usr_lib_byobu_include_dirs_in
│   ├── patch-usr_lib_byobu_include_shutil
│   ├── patch-usr_lib_byobu_ip_address
│   ├── patch-usr_lib_byobu_load_average
│   ├── patch-usr_lib_byobu_memory
│   ├── patch-usr_lib_byobu_network
│   ├── patch-usr_lib_byobu_processes
│   ├── patch-usr_lib_byobu_raid
│   ├── patch-usr_lib_byobu_swap
│   ├── patch-usr_lib_byobu_uptime
│   └── patch-usr_lib_byobu_wifi_quality
├── pkg/
│   ├── DESCR         # Port description
│   └── PLIST         # Port packing list
└── README.md
```

## Build Options

```sh
./build.sh                      # Build and install to /usr/local
./build.sh --prefix=/opt/byobu  # Custom install prefix
./build.sh --patch-only         # Apply patches without building
```

## Dependencies

**Build time**: autoconf, automake, curl, make

**Run time**: bash, tmux

## Upstream

Byobu upstream: https://github.com/dustinkirkland/byobu

These patches are against byobu 6.14. The FreeBSD port patches were used as a reference for structure, but all OpenBSD code paths are written for OpenBSD-specific interfaces (`sysctl hw.sensors`, `apm(8)`, `swapctl(8)`, `bioctl(8)`, `netstat -ibn`, etc.).

## License

Patches are licensed under GPLv3 to match byobu upstream.
