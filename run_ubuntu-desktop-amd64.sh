#!/usr/bin/env bash

# Tested on:
# Host ubuntu-22.04
# Guest qemu+ubuntu-23.04-desktop-amd64

set -eux

# Parameters.
OS_IMG=ubuntu-23.04-desktop-amd64
disk_img="${OS_IMG}.img.qcow2"
disk_img_snapshot="${OS_IMG}.snapshot.qcow2"
iso="${OS_IMG}.iso"

# Get image.
if [ ! -f "$iso" ]; then
  wget "https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/23.04/${iso}"
fi

# Go through installer manually.
if [ ! -f "$disk_img" ]; then
  qemu-img create -f qcow2 "$disk_img" 32G
  qemu-system-x86_64 \
    -cdrom "$iso" \
    -drive "file=${disk_img},format=qcow2" \
    -enable-kvm \
    -m 8G \
    -smp 4 \
  ;
fi

# Snapshot the installation.
if [ ! -f "$disk_img_snapshot" ]; then
  qemu-img \
    create \
    -b "$disk_img" \
    -f qcow2 \
    -F qcow2 \
    "$disk_img_snapshot" \
  ;
fi

# Run the installed image.
qemu-system-x86_64 \
  -drive "file=${disk_img_snapshot},format=qcow2" \
  -enable-kvm \
  -m 8G \
  -smp 4 \
  -net user,hostfwd=tcp::2222-:22 -net nic \
  -device virtio-gpu-gl-pci \
  -display gtk,gl=on \
  -vga none
  "$@" \
;
