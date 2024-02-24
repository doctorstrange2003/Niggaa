#!/bin/bash

#set -e

# Telegram Bot Integration
post_msg(){
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}

push(){
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
}

##----------------------------------------------------------##

## Copy this script inside the kernel directory
KERNEL_DEFCONFIG=vendor/miatoll-perf_defconfig
ANYKERNEL3_DIR=$PWD/AnyKernel3/
FINAL_KERNEL_ZIP=Niggatron-KSU-MiAtoll-$(date '+%Y%m%d').zip
export PATH="$HOME/cosmic/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_HOST=Github-CI
export KBUILD_BUILD_USER=TxExcalibur
export KBUILD_COMPILER_STRING="$($HOME/cosmic/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

if ! [ -d "$HOME/cosmic" ]; then
	then
    post_msg " Cloning Proton Clang 13 ToolChain "
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH" then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Clean build always lol
echo "**** Cleaning ****"
mkdir -p out
make O=out clean
make mrproper

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"

    # Push Notification
    post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>DockerOS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$VENDOR [$DEVICE]</code>%0A<b>Version : </b><code>$CUSTOM_VERSION</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Linker : </b><code>$LINKER</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
    
make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
		      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      LD=ld.lld \
                      LLVM=1 \
                      LLVM_IAS=1

echo "**** Verify Image.gz, dtbo.img & dtb ****"
ls $PWD/out/arch/arm64/boot/Image.gz
ls $PWD/out/arch/arm64/boot/dtbo.img
ls $PWD/out/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb

# Anykernel 3 time!!
echo "**** Verifying AnyKernel3 Directory ****"
ls $ANYKERNEL3_DIR
echo "**** Removing leftovers ****"
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

echo "**** Copying Image.gz , dtbo.img & dtb ****"
cp $PWD/out/arch/arm64/boot/Image.gz $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb $ANYKERNEL3_DIR/dtb

echo "**** Time to zip up! ****"
cd $ANYKERNEL3_DIR/
zip -r9 "../$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP

echo "**** Done, here is your sha1 ****"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/dtb
rm -rf out/

sha1sum $FINAL_KERNEL_ZIP

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
post_msg="Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
curl -v -F chat_id=$chat_id -F document=@$FINAL_KERNEL_ZIP -F caption="$post_msg" https://api.telegram.org/bot$token/sendDocument
