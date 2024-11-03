#!/bin/bash

mkdir -p /build/zerolte

./utilities/mkdtimg cfg_create build/zerolte/dtbo.img dtconfigs/zerolte.cfg -d arch/arm64/boot/dts
