echo "Clean build? (1/0)"
read cleanbuild
echo "Make dtbo.img? (1/0)"
read makedtbo
if [ $cleanbuild = 1 ]
then
	make clean O=out
	make mrproper O=out
	rm -rf out
	mkdir out
fi
rm -rf AnyKernel3
git clone https://github.com/ShivamKumar2002/LLVM-Clang-11 llvm-clang --depth=1
git clone https://github.com/ShivamKumar2002/AnyKernel3 AnyKernel3 --depth=1
git clone https://android.googlesource.com/platform/system/libufdt scripts/ufdt/libufdt
export PATH=$(pwd)/llvm-clang/bin:$PATH
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="amazon_aws"
export KBUILD_BUILD_USER="shivam"
make vendor/violet-perf_defconfig ARCH=arm64 O=out
make -j$(nproc --all) \
	O=out \
	ARCH=arm64 \
	CC=clang \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi- | tee full.log
if [ ! -f out/arch/arm64/boot/Image.gz-dtb ]
then
	exit
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/
if [ $makedtbo = 1 ]
then
	python2 scripts/ufdt/libufdt/utils/src/mkdtboimg.py create out/arch/arm64/boot/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/sm6150-idp-overlay.dtbo
fi
cp out/arch/arm64/boot/dtbo.img AnyKernel3/
cd AnyKernel3
zip -r9 "m4st3rkernel-dtbo-$(TZ=Asia/Kolkata date +'%M%H-%d%m%Y').zip" *
