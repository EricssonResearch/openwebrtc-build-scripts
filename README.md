Build scripts for OpenWebRTC
============================

This repository is used as a submodule for [the main OpenWebRTC repository](https://github.com/EricssonResearch/openwebrtc). It contains scripts to bootstrap a build environment, build dependencies and also the build system infrastructure.

You don't need to clone it separately to the `openwebrtc` repository. If you cloned the `openwebrtc` repository recursively then you already have this in the `openwebrtc/scripts/` subdirectory. If you cloned `openwebrtc` without the `--recursive` option, you may need to run:
```
cd openwebrtc
git submodule init
git submodule update
```
...and then you will have the desired setup.

Build instructions are found [here](https://github.com/EricssonResearch/openwebrtc#building).
