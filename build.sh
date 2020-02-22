PROJECT_DIR=`pwd`
LINUX_DIR="stm32"
AFBOOT_DIR="afboot-stm32"
BOARD=stm32f429i-disco
ROOTFS_DIR="rootfs"
TOOLCHAIN=$PROJECT_DIR/tools/gcc-arm-none-eabi-4_9-2015q3/bin/arm-none-eabi-
S=$EUID;

if [ $S -ne 0 ]; then
	echo "You are not root!";
	exit 0
fi
	
#make af-boot
cd $AFBOOT_DIR
make $BOARD CROSS_COMPILE=$TOOLCHAIN 

#make kernel
cd $PROJECT_DIR/$LINUX_DIR
#make ARCH=arm CROSS_COMPILE=arm-none-eabi- stm32_defconfig
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN CONFIGS=../$PROJECT_DIR/configs/$BOARD -j 4

cat $PROJECT_DIR/$LINUX_DIR/arch/arm/boot/xipImage > $PROJECT_DIR/$LINUX_DIR/arch/arm/boot/xipImage.bin

#make rootfs.cpio
cd $PROJECT_DIR/$ROOTFS_DIR
sudo find . | cpio --quiet -o -H newc > $PROJECT_DIR/rootfs.cpio


cd $PROJECT_DIR
#flash to target

openocd -f  board/stm32f429discovery.cfg \
 -c "init" \
 -c "reset init" \
 -c "flash probe 0" \
 -c "flash info 0" \
 -c "flash write_image erase $PROJECT_DIR/$AFBOOT_DIR/$BOARD.bin 0x08000000" \
 -c "flash write_image erase $PROJECT_DIR/$LINUX_DIR/arch/arm/boot/xipImage.bin 0x08008000" \
 -c "flash write_image erase $PROJECT_DIR/$LINUX_DIR/arch/arm/boot/dts/stm32f429-disco.dtb 0x08004000" \
 -c "reset run" \
 -c "shutdown"

