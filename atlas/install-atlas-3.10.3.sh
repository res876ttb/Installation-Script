#!/bin/bash

####{{{ parameter

# package name and its version
pkg=atlas-3.10.3
src=ATLAS

# url of source code
url=https://sourceforge.net/projects/math-atlas/files/Stable/3.10.3/atlas3.10.3.tar.bz2

# url of lapack
lapack_url=http://www.netlib.org/lapack/lapack-3.8.0.tar.gz
lapack=lapack-3.8.0.tar.gz

# name of downloaded file
zip=atlas3.10.3.tar.bz2

# target directory
td=$HOME/.pkg/$pkg

# script path
sp=$HOME/.script/env-$pkg.sh

# environment script
env="\
  export LD_LIBRARY_PATH=$td/lib:\$LD_LIBRARY_PATH \
  export INCLUDE=$td/include:\$INCLUDE \
"

# ramdisk path
ramdisk=/tmp/ramdisk-$pkg

# scripts of required packages
required=" \
  $HOME/.script/env-cmake-3.11.2.sh \
  $HOME/.script/env-zlib-1.2.11.sh \
  $HOME/.script/env-hdf5-1.10.2.sh \
  $HOME/.script/env-curl-7.60.0.sh \
  $HOME/.script/env-openssl-1.1.0.sh \
  $HOME/.script/env-netcdf-4.6.1.sh \
"

 #}}}
####{{{ variable

clearmode=0
quietmode=0
curpath=

#}}}
####{{{ function

# command
function cm {
  if [ $quietmode -eq 0 ]; then
    $1
    ce $? "$2"
  else
    $1 &>> ~/$pkg.log
    ce $? "$2"
  fi
}

# check error
function ce {
  if [ $1 -ne 0 ]; then
    echo "*** Error! ***"
    echo Errors occur when $2
    exit -1
  fi
}

#}}}
####{{{ main script 

# ================================================= read option
while [ $# -gt 0 ]; do
  case $1 in
    -c | --clear)
      echo [ clear mode ]
      clearmode=1
      shift
      ;;
    -q | --quiet)
      echo [ quiet mode ]
      quietmode=1
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "-c --clear    clear directory"
      echo "-q --quiet    redirect output to file ~/$pkg.log"
      exit -1
  esac
done

# ================================================= set environment
for i in $required; do
  if [ ! -f $i ]; then
    echo File $i not exists!
    exit -1
  fi
  echo source $i
  source $i
done

# ================================================= remove log file
rm -rf ~/$pkg.log

# ================================================= clear option
if [ $clearmode -gt 0 ]; then
  echo Clearing environment, script, and target directory...
  rm -rf $pkg $src $sp $zip $td ~/$pkg.log $ramdisk
  exit
fi

# ================================================= show warning messages
echo "Need more than 7 hours to compile ATLAS."
echo "Continue? (press enter to continue, or press ctrl+c to exit)"
read x

# ================================================= download
echo Downloading $pkg...
if [ -f $zip ]; then
  echo File $zip exists! Skip download stage.
else
  cm "wget $url" "download $pkg"
fi

# ================================================= copy data to ramdisk
mkdir -p $ramdisk
curpath=$PWD
cp $zip $ramdisk/
cd $ramdisk

# ================================================= download lapack
echo Downloading $lapack...
cm "wget $lapack_url" "download $lapack"

# ================================================= unzip
echo Unzipping $pkg...
rm -rf $src
cm "tar jxf $zip" "untar $zip"

# ================================================= build
echo Building $pkg...
cd $src
mkdir build
cd build
cm "../configure --prefix=$td --cripple-atlas-performance --with-netlib-lapack-tarfile=$PWD/../../$lapack" "configure $pkg"
cm "make build" "build $pkg"
cm "make check" "check $pkg"
cm "make ptcheck" "ptcheck $pkg"
cm "make time" "benchmark $pkg"

# ================================================= install
echo Installing $pkg
cm "make install" "install $pkg"

# ================================================= clear environment
echo Clearing environment...
cd $curpath
rm -rf $ramdisk ~/$pkg.log

# ================================================= create script
echo Creating script for $pkg...
mkdir -p $HOME/.script
echo $env > $sp
chmod +x $sp

# ================================================= DONE!
echo Done!
#}}}
