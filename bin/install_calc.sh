#! /bin/sh
# installs calc into /usr/local

set -x

version=calc-2.12.5.0
patch=$PWD/$(dirname $0)/makefile.patch

cd /tmp
wget -nv http://www.isthe.com/chongo/src/calc/${version}.tar.bz2
tar xjf ${version}.tar.bz2
cd $version
patch -p0 < $patch
make && make check && sudo make install
