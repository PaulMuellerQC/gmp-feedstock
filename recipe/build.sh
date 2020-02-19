#!/bin/bash

shopt -s extglob
chmod +x configure

if [[ "$target_platform" == "linux-ppc64le" ]]; then
  # HOST="powerpc64le-conda-linux-gnu" masks the fact that we are only
  # building for power8 and uses an older POWER architecture.
  GMP_HOST="power8-pc-linux-gnu"
elif [[ "$target_platform" == "linux-aarch64" ]]; then
  # Support generic arm64.
  GMP_HOST="arm64-pc-linux-gnu"
else
  GMP_HOST=$HOST
fi

./configure --prefix=$PREFIX --enable-cxx --enable-fat --host=$GMP_HOST

make -j${CPU_COUNT}
make check -j${CPU_COUNT}
make install

if [[ "$target_platform" == "linux-ppc64le" ]]; then
    # Build a Power9 library as well
    ./configure --prefix=$PREFIX --enable-cxx --enable-fat --host="power9-pc-linux-gnu"
    make -j${CPU_COUNT}
    make install DESTDIR=$PWD/install
    # Install just the library to $PREFIX/lib/power9
    # Since $PREFIX/lib is in the rpath, newer glibc will look in
    # $PREFIX/lib/power9 before $PREFIX/lib
    # See Rpath token expansion in http://man7.org/linux/man-pages/man8/ld.so.8.html
    # This is only done for powerpc because GMP has a fat binary for x86 and I
    # couldn't find how to do it for arm64 and not sure whether that's beneficial.
    mkdir -p $PREFIX/lib/power9
    cp $PWD/install$PREFIX/lib/libgmp.so.+([0-9]) $PREFIX/lib/power9
fi
