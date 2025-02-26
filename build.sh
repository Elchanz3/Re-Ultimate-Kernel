#!/bin/bash
#
# Thanks to Tkkg1994 and djb77 for the script
#
# MoRoKernel Build Script v1.2
#
# For
#
# Ultimate-Kernel
#

# SETUP
# -----
export ARCH=arm64
export SUBARCH=arm64
export BUILD_CROSS_COMPILE=/home/chanz22/tc/gcc-linaro-4.9.4-2017.01-x86_64_aarch64-elf/bin/aarch64-elf-
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export USE_CCACHE=1

export PLATFORM_VERSION=7.0

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0

DEFCONFIG=ultimate_defconfig
DEFCONFIG_S6EDGE=ultimate_defconfig_edge
DEFCONFIG_S6FLAT=ultimate_defconfig_flat
TMOBILE_DEFCONFIG=ultimate_defconfig_tmobile

export K_VERSION="v1.8.5"
export K_NAME="Re-Ultimate-Kernel"
export REVISION="RC"
export KBUILD_BUILD_VERSION="1"
S6DEVICE="Nougat"
EDGE_LOG=Edge_build.log
FLAT_LOG=Flat_build.log


# FUNCTIONS
# ---------
FUNC_CLEAN_DTB()
{
	if ! [ -d $RDIR/arch/$ARCH/boot/dts ] ; then
		echo "no directory : "$RDIR/arch/$ARCH/boot/dts""
	else
		echo "rm files in : "$RDIR/arch/$ARCH/boot/dts/*.dtb""
		rm $RDIR/arch/$ARCH/boot/dts/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb.img
		rm $RDIR/arch/$ARCH/boot/Image
		rm -rf $RDIR/build/ak3/Image
		rm -rf $RDIR/build/ak3/dtb.img
	fi
}

FUNC_BUILD_KERNEL()
{
	echo ""
        echo "build common config="$KERNEL_DEFCONFIG ""
        echo "build variant config="$MODEL ""

	cp -f $RDIR/arch/$ARCH/configs/$DEFCONFIG $RDIR/arch/$ARCH/configs/tmp_defconfig
	cat $RDIR/arch/$ARCH/configs/$KERNEL_DEFCONFIG >> $RDIR/arch/$ARCH/configs/tmp_defconfig

if [ $TMOBILE == "1" ]; then
    cat $RDIR/arch/$ARCH/configs/$TMOBILE_DEFCONFIG >> $RDIR/arch/$ARCH/configs/tmp_defconfig
fi

	#FUNC_CLEAN_DTB

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			tmp_defconfig || exit -1
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""

	rm -f $RDIR/arch/$ARCH/configs/tmp_defconfig
}

FUNC_BUILD_DTB()
{
	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}

if [ $TMOBILE == "1" ]; then
    case $MODEL in
	G920)
		DTSFILES="exynos7420-zeroflte_usa_00 exynos7420-zeroflte_usa_01 exynos7420-zeroflte_usa_02 exynos7420-zeroflte_usa_03 exynos7420-zeroflte_usa_04 exynos7420-zeroflte_usa_05"
		;;
	G925)
		DTSFILES="exynos7420-zerolte_usa_01 exynos7420-zerolte_usa_02 exynos7420-zerolte_usa_03 exynos7420-zerolte_usa_04 exynos7420-zerolte_usa_05 exynos7420-zerolte_usa_06 exynos7420-zerolte_usa_07 exynos7420-zerolte_usa_08"
		;;
    *)
    echo "Unknown device: $MODEL"
	exit 1
	;;
	esac
else
    case $MODEL in
    G920)
		DTSFILES="exynos7420-zeroflte_eur_open_00 exynos7420-zeroflte_eur_open_01 exynos7420-zeroflte_eur_open_02 exynos7420-zeroflte_eur_open_03 exynos7420-zeroflte_eur_open_04 exynos7420-zeroflte_eur_open_05 exynos7420-zeroflte_eur_open_06 exynos7420-zeroflte_eur_open_07"
		;;
	G925)
		DTSFILES="exynos7420-zerolte_eur_open_01 exynos7420-zerolte_eur_open_02 exynos7420-zerolte_eur_open_03 exynos7420-zerolte_eur_open_04 exynos7420-zerolte_eur_open_05 exynos7420-zerolte_eur_open_06 exynos7420-zerolte_eur_open_07 exynos7420-zerolte_eur_open_08"
		;;
    *)
    echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
fi

	mkdir -p $OUTDIR $DTBDIR
	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}
	rm -f ./*
	echo "Processing dts files."
	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done
	echo "Generating dtb.img."
	$RDIR/scripts/dtbtool_exynos/dtbtool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
	echo "Done."
}

FUNC_CP_AK3()
{
	echo ""
	echo "Copying kernel and dtb image to AnyKernel3 Folder"
	mv $RDIR/arch/$ARCH/boot/Image $RDIR/build/ak3/Image
	mv $RDIR/arch/$ARCH/boot/dtb.img $RDIR/build/ak3/dt.img
}

FUNC_BUILD_FLASHABLES()
{
	cd $RDIR/build/ak3
	echo ""
	echo "Creating flashables..."
	zip -r9 ../$ZIP_NAME * -x README.md ../$ZIP_NAME
}

CLEAN()
{
	# Clean Build Data
	make clean
	make ARCH=arm64 distclean
	rm -rf $RDIR/build/ak3/Image
	rm -rf $RDIR/build/ak3/dtb.img

	# Remove Release files
	rm -f $PWD/arch/arm64/configs/tmp_defconfig

	# Removed Created dtb Folder
	rm -rf $PWD/arch/arm64/boot/dtb
}



# MAIN PROGRAM
# ------------

MAIN()
{

(
	START_TIME=`date +%s`
	FUNC_BUILD_KERNEL
	FUNC_BUILD_DTB
	FUNC_CP_AK3
	FUNC_BUILD_FLASHABLES
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
	echo ""
) 2>&1 | tee -a ./$LOG

	echo "Your flasheable release can be found in the build folder"
	echo ""
}

MAIN2()
{

(
	START_TIME=`date +%s`
	FUNC_BUILD_KERNEL
	FUNC_BUILD_DTB
	FUNC_CP_AK3
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
	echo ""
) 2>&1 | tee -a ./$LOG

	echo "Your flasheable release can be found in the build folder"
	echo ""
}


# PROGRAM START
# -------------
clear
echo "**********************************"
echo "Ultimate-Kernel Build Script"
echo "**********************************"
echo ""
echo ""
echo "Build Kernel for:"
echo ""
echo "S6 Nougat"
echo "(1) S6 Flat SM-G920F"
echo "(2) S6 Edge SM-G925F"
echo "(3) S6 Edge + Flat International"
echo "(4) S6 Flat SM-G920T"
echo "(5) S6 Edge SM-G925T"
echo "(6) S6 Edge + Flat Tmobile"
echo "(7) CLEAN"
echo ""
echo ""
read -p "Select an option to compile the kernel " prompt


if [ $prompt == "1" ]; then
    MODEL=G920
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=0
    LOG=$FLAT_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 Flat G920F Selected"
    ZIP_NAME=$K_NAME-$MODEL-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "2" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=0
    LOG=$EDGE_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 Edge G925F Selected"
    ZIP_NAME=$K_NAME-$MODEL-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "3" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=0
    LOG=$EDGE_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 EDGE + FLAT International Selected"
    echo "Compiling EDGE ..."
    MAIN2
    MODEL=G920
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=0
    LOG=$FLAT_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "Compiling FLAT ..."
    ZIP_NAME=$K_NAME-G92X-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "4" ]; then
    MODEL=G920
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=1
    LOG=$FLAT_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 Flat G920T Selected"
    ZIP_NAME=$K_NAME-$MODELT-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "5" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=1
    LOG=$EDGE_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 Edge G925T Selected"
    ZIP_NAME=$K_NAME-$MODELT-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "6" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=1
    LOG=$EDGE_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "S6 EDGE + FLAT Tmobile Selected"
    echo "Compiling EDGE ..."
    MAIN2
    MODEL=G920
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=1
    LOG=$FLAT_LOG
    export KERNEL_VERSION="$K_NAME-Nougat-$K_VERSION"
    echo "Compiling FLAT ..."
    ZIP_NAME=$K_NAME-G92XT-N-$K_VERSION.zip
    MAIN
elif [ $prompt == "7" ]; then
    echo "Cleaning source directory..."
    CLEAN
fi
