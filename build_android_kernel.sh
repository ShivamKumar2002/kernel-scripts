echo "Clean build? (1/0)"
read cleanbuild
usellvm=1
if [ $cleanbuild = 1 ]
then
	echo "Cleaning..."
	make clean O=out
	make mrproper O=out
	rm -rf out
	mkdir out
fi
rm -rf AnyKernel3
echo "Cloning Repos..."
git clone https://github.com/ShivamKumar2002/M4ST3R-Clang-11 m4st3r-clang --depth=1
git clone https://github.com/ShivamKumar2002/AnyKernel3 AnyKernel3 --depth=1
git clone https://android.googlesource.com/platform/system/libufdt scripts/ufdt/libufdt
build_start=$(date +"%s")
export PATH=$(pwd)/m4st3r-clang/bin:$PATH
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="m4st3r_host"
export KBUILD_BUILD_USER="ShivamKumar2002"
echo "Making Config..."
make vendor/violet-perf_defconfig ARCH=arm64 O=out
if [ $usellvm = 1 ]
then
	makecommands+=(
		AR=llvm-ar \
		NM=llvm-nm \
		OBJCOPY=llvm-objcopy \
		OBJDUMP=llvm-objdump \
		STRIP=llvm-strip \
		READOBJ=llvm-readobj \
		READELF=llvm-readelf
	)
fi
makecommands+=(
	O=out \
	ARCH=arm64 \
	CC=clang \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
)
echo "Starting Compilation..."
make -j$(nproc --all) "${makecommands[@]}" | tee full.log
if [ ! -f out/arch/arm64/boot/Image.gz-dtb ]
then
	echo "Compilation Failed. Check full.log"
	exit
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/
echo "Making DTBO..."
python2 scripts/ufdt/libufdt/utils/src/mkdtboimg.py create out/arch/arm64/boot/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/sm6150-idp-overlay.dtbo
echo "Making Zip..."
cp out/arch/arm64/boot/dtbo.img AnyKernel3/
cd AnyKernel3
zip -r9 "m4st3rkernel-violet-dtbo-$(TZ=Asia/Kolkata date +'%M%H-%d%m%Y').zip" *
build_complete=$(date +"%s")
elapsed=$((build_complete-build_start))
echo "Completed Successfully in $elapsed Seconds."
echo "Zip is Ready. Go Flash and Enjoy Bootloop."
