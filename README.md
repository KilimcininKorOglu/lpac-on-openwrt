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

## Installation

### Prerequisites

You need an OpenWRT build environment set up on your system.

### Integration Steps

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

## Project Links

- **Upstream lpac source code**: [https://github.com/estkme-group/lpac](https://github.com/estkme-group/lpac)
- **OpenWRT**: [https://openwrt.org](https://openwrt.org)
