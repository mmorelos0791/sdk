#!/bin/sh

MEGACHAT_VERSION="GIT"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

##############################################
CURRENTPATH=`pwd`
OPENSSL_PREFIX="${CURRENTPATH}"
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

case $CURRENTPATH in
     *\ * )
           echo "Your path contains whitespaces, which is not supported by 'make install'."
           exit 1
          ;;
esac

set -e

if [ ! -d "karere-native" ]
then
git clone --recursive https://code.developers.mega.co.nz/messenger/karere-native
git branch feature/mega-chat-api
fi

if [ ! -d "include/webrtc" ]
then
    WEBRTC_REVISION=9ac4df1ba66d39c3621cfb2e8ed08ae39658b793
    mkdir -p webrtc
    pushd webrtc
    git init
    git remote add origin https://chromium.googlesource.com/external/webrtc.git
    git fetch --depth=1 origin ${WEBRTC_REVISION}
    git checkout ${WEBRTC_REVISION}
    popd
    ln -s ../webrtc/webrtc include/webrtc
    ln -s ../../mega include/mega
fi

for ARCH in ${ARCHS}
do

if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi

echo "BUILDING FOR ${ARCH}"

IOSC_TARGET=iphoneos
IOSC_OS_VERSION=-mios-version-min=7.0
IOSC_ARCH=${ARCH}
IOSC_PLATFORM_SDKNAME=${PLATFORM}
IOSC_CMAKE_TOOLCHAIN="../ios.toolchain.cmake"
IOSC_SYSROOT=`xcrun -sdk $IOSC_TARGET -show-sdk-path`
# the same as SDKROOT

pushd karere-native/src
git reset --hard && git clean -dfx

export BUILD_TOOLS="${DEVELOPER}"
export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=7.0 -L${BUILD_SDKROOT}/usr/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=7.0"
export CPPFLAGS="${CFLAGS} -I${BUILD_SDKROOT}/usr/include"
export CXXFLAGS="${CPPFLAGS}"

if [ "${ARCH}" == "arm64" ]; then

IOSC_HOST_TRIPLET=aarch64-apple-darwin

/Applications/CMake.app/Contents/bin/cmake . -D_LIBMEGA_LIBRARIES= -DLIBMEGA_PUBLIC_INCLUDE_DIR=../../../../../include -DCMAKE_SYSROOT=${CURRENTPATH} -DCMAKE_TOOLCHAIN_FILE=${CURRENTPATH}/iOS.cmake -DIOS_PLATFORM=OS -DIOS_PLATFORM_TYPE=${ARCH} -DBUILD_ARM64=1 -DCMAKE_LIBRARY_PATH=${CURRENTPATH}/lib -DCMAKE_INCLUDE_PATH=${CURRENTPATH}/include -DLIBEVENT_INCLUDE_DIRS=${CURRENTPATH}/include/libevent -DLIBEVENT_LIB_CORE=${CURRENTPATH}/lib -DLIBEVENT_LIB_EXTRA=${CURRENTPATH}/lib -DLIBEVENT_LIB_OPENSSL=${CURRENTPATH}/lib -DLIBEVENT_LIB_PTHREADS=${CURRENTPATH}/lib -DOPENSSL_INCLUDE_DIR=${CURRENTPATH}/include -DOPENSSL_SSL_LIBRARY=${CURRENTPATH}/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=${CURRENTPATH}/lib/libcrypto.a -DOPENSSL_ROOT_DIR=${CURRENTPATH} -DLIBEVENT_LIB=${CURRENTPATH}/lib/libevent.a

elif [ "${ARCH}" == "i386" ]; then

IOSC_HOST_TRIPLET=${ARCH}-apple-darwin

/Applications/CMake.app/Contents/bin/cmake . -D_LIBMEGA_LIBRARIES= -DLIBMEGA_PUBLIC_INCLUDE_DIR=../../../../../include -DCMAKE_SYSROOT=${CURRENTPATH} -DCMAKE_TOOLCHAIN_FILE=${CURRENTPATH}/iOS.cmake -DIOS_PLATFORM=SIMULATOR -DCMAKE_LIBRARY_PATH=${CURRENTPATH}/lib -DCMAKE_INCLUDE_PATH=${CURRENTPATH}/include -DLIBEVENT_INCLUDE_DIRS=${CURRENTPATH}/include/libevent -DLIBEVENT_LIB_CORE=${CURRENTPATH}/lib -DLIBEVENT_LIB_EXTRA=${CURRENTPATH}/lib -DLIBEVENT_LIB_OPENSSL=${CURRENTPATH}/lib -DLIBEVENT_LIB_PTHREADS=${CURRENTPATH}/lib -DOPENSSL_INCLUDE_DIR=${CURRENTPATH}/include -DOPENSSL_SSL_LIBRARY=${CURRENTPATH}/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=${CURRENTPATH}/lib/libcrypto.a -DOPENSSL_ROOT_DIR=${CURRENTPATH} -DLIBEVENT_LIB=${CURRENTPATH}/lib/libevent.a

elif [ "${ARCH}" == "x86_64" ]; then

IOSC_HOST_TRIPLET=${ARCH}-apple-darwin

/Applications/CMake.app/Contents/bin/cmake . -D_LIBMEGA_LIBRARIES= -DLIBMEGA_PUBLIC_INCLUDE_DIR=../../../../../include -DCMAKE_SYSROOT=${CURRENTPATH} -DCMAKE_TOOLCHAIN_FILE=${CURRENTPATH}/iOS.cmake -DIOS_PLATFORM=SIMULATOR64 -DCMAKE_LIBRARY_PATH=${CURRENTPATH}/lib -DCMAKE_INCLUDE_PATH=${CURRENTPATH}/include -DLIBEVENT_INCLUDE_DIRS=${CURRENTPATH}/include/libevent -DLIBEVENT_LIB_CORE=${CURRENTPATH}/lib -DLIBEVENT_LIB_EXTRA=${CURRENTPATH}/lib -DLIBEVENT_LIB_OPENSSL=${CURRENTPATH}/lib -DLIBEVENT_LIB_PTHREADS=${CURRENTPATH}/lib -DOPENSSL_INCLUDE_DIR=${CURRENTPATH}/include -DOPENSSL_SSL_LIBRARY=${CURRENTPATH}/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=${CURRENTPATH}/lib/libcrypto.a -DOPENSSL_ROOT_DIR=${CURRENTPATH} -DLIBEVENT_LIB=${CURRENTPATH}/lib/libevent.a

else

IOSC_HOST_TRIPLET=${ARCH}-apple-darwin

/Applications/CMake.app/Contents/bin/cmake . -D_LIBMEGA_LIBRARIES= -DLIBMEGA_PUBLIC_INCLUDE_DIR=../../../../../include -DCMAKE_SYSROOT=${CURRENTPATH} -DCMAKE_TOOLCHAIN_FILE=${CURRENTPATH}/iOS.cmake -DIOS_PLATFORM=OS -DIOS_PLATFORM_TYPE=${ARCH} -DCMAKE_LIBRARY_PATH=${CURRENTPATH}/lib -DCMAKE_INCLUDE_PATH=${CURRENTPATH}/include -DLIBEVENT_INCLUDE_DIRS=${CURRENTPATH}/include/libevent -DLIBEVENT_LIB_CORE=${CURRENTPATH}/lib -DLIBEVENT_LIB_EXTRA=${CURRENTPATH}/lib -DLIBEVENT_LIB_OPENSSL=${CURRENTPATH}/lib -DLIBEVENT_LIB_PTHREADS=${CURRENTPATH}/lib -DOPENSSL_INCLUDE_DIR=${CURRENTPATH}/include -DOPENSSL_SSL_LIBRARY=${CURRENTPATH}/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=${CURRENTPATH}/lib/libcrypto.a -DOPENSSL_ROOT_DIR=${CURRENTPATH} -DLIBEVENT_LIB=${CURRENTPATH}/lib/libevent.a
fi

CMAKE_XCOMPILE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$IOSC_CMAKE_TOOLCHAIN -DCMAKE_INSTALL_PREFIX=$IOSC_BUILDROOT"
CONFIGURE_XCOMPILE_ARGS="--prefix=$IOSC_BUILDROOT --host=$IOSC_HOST_TRIPLET"

make

cp -f libkarere.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/libkarere.a
cp -f rtcModule/base/libservices.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/libservices.a
cp -f rtcModule/base/strophe/libstrophe.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/libstrophe.a
cp -f rtcModule/librtcmodule.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/librtcmodule.a
cp -f rtcModule/webrtc/libwebrtc_my.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/libwebrtc_my.a

popd

done


mkdir lib || true
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libkarere.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libkarere.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libkarere.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libkarere.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libkarere.a -output ${CURRENTPATH}/lib/libkarere.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libservices.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libservices.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libservices.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libservices.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libservices.a -output ${CURRENTPATH}/lib/libservices.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libstrophe.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libstrophe.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libstrophe.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libstrophe.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libstrophe.a -output ${CURRENTPATH}/lib/libws.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/librtcmodule.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/librtcmodule.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/librtcmodule.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/librtcmodule.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/librtcmodule.a -output ${CURRENTPATH}/lib/librtcmodule.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libwebrtc_my.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libwebrtc_my.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libwebrtc_my.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libwebrtc_my.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libwebrtc_my.a -output ${CURRENTPATH}/lib/libwebrtc_my.a

mkdir -p include || true
cp -f karere-native/src/megachatapi.h include/

#rm -rf bin
#rm -rf expat-${EXPAT_VERSION}
#rm -rf expat-${EXPAT_VERSION}.tar.bz2

echo "Done."
