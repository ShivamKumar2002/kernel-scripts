echo "Clean build? (1/0)"
read cleanbuild
if [ $cleanbuild = 1 ]
echo "Cleaning..."
then
	make clean O=out
	make mrproper O=out
	rm -rf out
	mkdir out
fi
rm -rf AnyKernel3
echo "Cloning Repos..."
git clone https://github.com/ShivamKumar2002/LLVM-Clang-11 llvm-clang --depth=1
git clone https://github.com/ShivamKumar2002/AnyKernel3 AnyKernel3 --depth=1
git clone https://android.googlesource.com/platform/system/libufdt scripts/ufdt/libufdt
build_start=$(date +"%s")
export PATH=$(pwd)/llvm-clang/bin:$PATH
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="amazon_aws"
export KBUILD_BUILD_USER="shivam"
echo "Making Config..."
make vendor/violet-perf_defconfig ARCH=arm64 O=out
echo "Starting Compilation..."
make -j$(nproc --all) \
	O=out \
	ARCH=arm64 \
	CC=clang \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi- | tee full.log
if [ ! -f out/arch/arm64/boot/Image.gz-dtb ]
then
	echo "Compilation Failed. Check full.log"
	exit
fi
build_complete=$(date +"%s")
elapsed=$((build_complete-build_start))
echo "Compiled Successfully in $elapsed Seconds."
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/
echo "Making DTBO..."
python2 scripts/ufdt/libufdt/utils/src/mkdtboimg.py create out/arch/arm64/boot/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/sm6150-idp-overlay.dtbo
echo "Making Zip..."
cp out/arch/arm64/boot/dtbo.img AnyKernel3/
cd AnyKernel3
zip -r9 "m4st3rkernel-violet-dtbo-$(TZ=Asia/Kolkata date +'%M%H-%d%m%Y').zip" *
echo "Zip is Ready. Go Flash and Enjoy Bootloop."
