# lpac on OpenWRT (2.0.0)

## Introduction

lpac is a eUICC eSIM LPA manager written in C. It allows to manage eSIM profiles on eUICC SIM cards or modules using multiple backends.

## Installation

Go to your OpenWRT build root, clone this repository into `packages/util` then update and install new feeds:

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

Then run `make menuconfig` and select it under:

- **Utilities** → **lpac**

## Project Source Code

Upstream lpac project: [https://github.com/estkme-group/lpac](https://github.com/estkme-group/lpac)
