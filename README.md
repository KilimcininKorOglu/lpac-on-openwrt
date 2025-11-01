# lpac on OpenWRT (2.0.0)

## What is This Repository?

This is an **OpenWRT package repository** for lpac, not the lpac source code itself. It contains the necessary build configuration files (Makefile and patches) to compile and package lpac for OpenWRT routers.

The actual lpac source code is automatically fetched from the upstream repository during the build process.

## What is lpac?

lpac is a cross-platform eUICC eSIM LPA (Local Profile Agent) manager written in C. It enables management of eSIM profiles on eUICC SIM cards or modules.

**Key features:**

- Activate eSIM profiles using Activation Code and Confirm Code
- Custom IMEI support for server communication
- Profile Discovery via SM-DS
- Profile management: list, enable, disable, delete, and nickname profiles
- Notification management: list, send, and delete notifications
- eUICC chip information lookup

## Quick Start

### Method 1: Automated Build Script (Recommended)

The easiest way to build lpac for OpenWRT:

```bash
# Make script executable
chmod +x build-lpac-openwrt.sh

# Build with defaults (24.10.4, x86_64)
./build-lpac-openwrt.sh

# Build for specific platform
./build-lpac-openwrt.sh 24.10.4 x86 64

# Build for Raspberry Pi 4
./build-lpac-openwrt.sh 24.10.4 bcm27xx bcm2711

# Show help and available options
./build-lpac-openwrt.sh --help

# List supported target platforms
./build-lpac-openwrt.sh --list-targets
```

The script will automatically:

1. Check and install required dependencies
2. Download OpenWRT source code
3. Setup feeds
4. Integrate lpac package
5. Configure build system
6. Build toolchain
7. Compile lpac package
8. Output the final `.ipk` package

### Method 2: Manual Integration

For advanced users who already have an OpenWRT build environment:

1. Go to your OpenWRT build root directory and clone this repository into `package/utils`:

```bash
cd <openwrt-build-root>/package/utils
git clone <this-repository-url> lpac
```

2. Update and install feeds:

```bash
cd <openwrt-build-root>
./scripts/feeds update -a
./scripts/feeds install -a
```

3. Configure the package in menuconfig:

```bash
make menuconfig
```

Navigate to: **Utilities** → **lpac** and select it.

4. Build the package:

```bash
make package/lpac/compile V=s
```

The compiled `.ipk` package will be available in `bin/packages/<architecture>/packages/`.

## Build Script Usage

### Command-Line Arguments

```bash
./build-lpac-openwrt.sh [VERSION] [TARGET] [SUBTARGET] [THREADS]
```

**Arguments:**

- `VERSION`: OpenWRT version (default: 24.10.4)
- `TARGET`: Target architecture (default: x86)
- `SUBTARGET`: Target sub-architecture (default: 64)
- `THREADS`: Number of parallel jobs (default: auto-detected)

**Options:**

- `-h, --help`: Show help message
- `-l, --list-targets`: List common target combinations
- `-c, --clean`: Clean build directory before building
- `-s, --skip-toolchain`: Skip toolchain build (use existing)

### Examples

```bash
# Build with defaults
./build-lpac-openwrt.sh

# Build specific version for x86
./build-lpac-openwrt.sh 24.10.4 x86 64

# Build for Raspberry Pi 4
./build-lpac-openwrt.sh 24.10.4 bcm27xx bcm2711

# Build with 8 threads
./build-lpac-openwrt.sh 24.10.4 x86 64 8

# Clean build
./build-lpac-openwrt.sh --clean

# Build for ARM generic with clean
./build-lpac-openwrt.sh --clean 24.10.4 armsr armv8
```

### Supported Target Platforms

Common target combinations:

**x86:**

- `x86 64` - 64-bit PC (AMD64/Intel 64)
- `x86 generic` - 32-bit PC (i386)

**Raspberry Pi:**

- `bcm27xx bcm2708` - Raspberry Pi 1
- `bcm27xx bcm2709` - Raspberry Pi 2
- `bcm27xx bcm2710` - Raspberry Pi 3
- `bcm27xx bcm2711` - Raspberry Pi 4

**ARM:**

- `armsr armv8` - ARM 64-bit generic
- `armsr armv7` - ARM 32-bit generic

**MediaTek:**

- `ramips mt7620` - MediaTek MT7620
- `ramips mt7621` - MediaTek MT7621
- `ramips mt76x8` - MediaTek MT76x8

**Qualcomm:**

- `ath79 generic` - Qualcomm Atheros AR71xx/AR724x/AR913x
- `ipq40xx generic` - Qualcomm IPQ40xx

Use `./build-lpac-openwrt.sh --list-targets` for the complete list.

## System Requirements

### Minimum Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 20GB free space
- **OS**: Ubuntu 20.04/22.04 or Debian 11/12

### Required Packages

The automated script checks and installs these automatically:

- build-essential
- libncurses5-dev
- gawk
- gettext
- unzip
- file
- libssl-dev
- wget
- python3
- rsync
- python3-distutils
- zlib1g-dev
- libelf-dev

## Build Time

Expected build times (varies by hardware):

- **First build** (includes toolchain): 30-120 minutes
- **Subsequent builds**: 5-15 minutes
- **Clean rebuild**: 10-30 minutes

## Output

After successful build, the package will be located at:

```
~/openwrt-build/lpac_24.10.4_x86_64.ipk
```

## Installation on OpenWRT Device

1. Copy the package to your router:

```bash
scp lpac_24.10.4_x86_64.ipk root@192.168.1.1:/tmp/
```

2. SSH into your router:

```bash
ssh root@192.168.1.1
```

3. Install the package:

```bash
opkg update
opkg install /tmp/lpac_24.10.4_x86_64.ipk
```

4. Verify installation:

```bash
lpac --version
```

## Technical Details

### Build System

- **Package Manager**: Uses OpenWRT's BuildPackage framework
- **Build Tool**: CMake (integrated via OpenWRT's cmake.mk)
- **Dependencies**: libopenssl, pcscd, libpcsclite, libcurl
- **Output**: Single binary `/usr/bin/lpac` installed to target system

### Patches

The `patches/` directory contains build patches automatically applied during compilation:

#### 001-add-fPIC.patch

This patch adds `-fPIC` (Position Independent Code) compiler flags to all CMakeLists.txt files in the lpac project.

**Why is this necessary?**

- OpenWRT requires Position Independent Code for shared libraries
- Enables proper linking of lpac's sub-components (cjson, euicc, etc.)
- Required for ASLR (Address Space Layout Randomization) security feature
- Allows efficient memory sharing in resource-constrained embedded systems
- Without this patch, compilation will fail with relocation errors

**Modified files:**

- Root CMakeLists.txt
- cjson/CMakeLists.txt
- dlfcn-win32/CMakeLists.txt
- euicc/CMakeLists.txt
- src/CMakeLists.txt

### Version Information

- **PKG_RELEASE**: 2.0.0 (package version)
- **PKG_SOURCE_VERSION**: Locked to specific upstream git commit
- **Upstream Repository**: [https://github.com/estkme-group/lpac](https://github.com/estkme-group/lpac)

## Troubleshooting

### Build Fails with "No space left on device"

- Ensure at least 20GB free space
- Clean previous builds: `rm -rf ~/openwrt-build`

### Dependency Installation Fails

- Update package lists: `sudo apt-get update`
- Check internet connection
- Verify Ubuntu/Debian version compatibility

### Toolchain Build Errors

- Check for missing dependencies
- Try with single thread: `./build-lpac-openwrt.sh 24.10.4 x86 64 1`
- Review build logs in `~/openwrt-build/openwrt/logs/`

### lpac Compilation Fails

- Verify patches apply cleanly
- Check if upstream lpac commit hash is still valid
- Review detailed errors with: `make package/lpac/compile V=s`

### Version Not Found

If OpenWRT version 24.10.4 is not available, the script will show available versions. Update the version argument accordingly.

## Advanced Usage

### Clean Build

Remove previous build artifacts and start fresh:

```bash
./build-lpac-openwrt.sh --clean
```

Or manually:

```bash
cd ~/openwrt-build/openwrt
make package/lpac/clean
make package/lpac/compile V=s
```

### Skip Toolchain Build

If toolchain is already built, skip it to save time:

```bash
./build-lpac-openwrt.sh --skip-toolchain
```

### Build with Debug Symbols

Edit `.config` in the OpenWRT build directory and add:

```text
CONFIG_DEBUG=y
```

### Limit Parallel Jobs

```bash
# Use only 4 threads
./build-lpac-openwrt.sh 24.10.4 x86 64 4
```

## Docker Alternative

For a clean, isolated build environment:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential git libncurses5-dev gawk gettext \
    unzip file libssl-dev wget python3 rsync \
    python3-distutils zlib1g-dev libelf-dev

WORKDIR /build
COPY build-lpac-openwrt.sh .
RUN chmod +x build-lpac-openwrt.sh

CMD ["./build-lpac-openwrt.sh"]
```

Build and run:

```bash
docker build -t openwrt-lpac-builder .
docker run -v $(pwd)/output:/build/output openwrt-lpac-builder
```

## Project Links

- **Upstream lpac source code**: [https://github.com/estkme-group/lpac](https://github.com/estkme-group/lpac)
- **OpenWRT**: [https://openwrt.org](https://openwrt.org)
- **OpenWRT Build System**: [https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem)
- **OpenWRT Package Development**: [https://openwrt.org/docs/guide-developer/packages](https://openwrt.org/docs/guide-developer/packages)
