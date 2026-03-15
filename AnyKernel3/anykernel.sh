### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Modified for A205F

### AnyKernel setup
# global properties
properties() { '
kernel.string=Wonderful for A205F
kernel.image=Image
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=a20
device.name2=a205f
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install

# boot partition
BLOCK=/dev/block/by-name/boot
IS_SLOT_DEVICE=0
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto

# import AnyKernel core
. tools/ak3-core.sh;

# unpack boot image
split_boot;

# flash kernel only
flash_boot;