#!/bin/bash

####{{{ parameter

# package name and its version
pkg=netcdf-fortran-4.4.4-intelmpi-intel
src=netcdf-fortran-4.4.4

# url of source code
url=ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.4.tar.gz

# name of downloaded file
zip=netcdf-fortran-4.4.4.tar.gz

# target directory
td=$HOME/.pkg/$pkg

# script path
sp=$HOME/.script/env-$pkg.sh

# environment script
env="\
  export PATH=$td/bin:\$PATH \
  export LD_LIBRARY_PATH=$td/lib:\$LD_LIBRARY_PATH \
  export INCLUDE=$td/include:\$INCLUDE \
  export CPATH=$td/include:\$CPATH \
"

# ramdisk path
ramdisk=/tmp/ramdisk-$pkg

# scripts of required packages
required=" \
  $HOME/.script/env-intel.sh \
  $HOME/.script/env-zlib-1.2.11.sh \
  $HOME/.script/env-hdf5-1.10.4-intelmpi-parallel.sh \
  $HOME/.script/env-curl-7.60.0.sh \
  $HOME/.script/env-openssl-1.1.0.sh \
  $HOME/.script/env-netcdf-4.6.2-intelmpi-intel.sh \
"

# Compilation flags
cflag=

 #}}}
####{{{ variable

clearmode=0
quietmode=0
skipcheck=0
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
    -s | --skip-check)
      echo [ skip check ]
      skipcheck=1
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "-c --clear       clear directory"
      echo "-q --quiet       redirect output to file ~/$pkg.log"
      echo "-s --skip-check  skip checking stage"
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
rm -rf $pkg.log

# ================================================= clear option
if [ $clearmode -gt 0 ]; then
  echo Clearing environment, script, and target directory...
  rm -rf $pkg $src $sp $td ~/$pkg.log $ramdisk
  exit
fi

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

# ================================================= unzip
echo Unzipping $pkg...
rm -rf $pkg
cm "tar zxf $zip" "untar $zip"

# ================================================= build
echo Building $pkg...
cd $src
export CPPFLAGS=-I$HOME/.pkg/netcdf-4.6.2-intelmpi-intel/include 
export LDFLAGS=-L$HOME/.pkg/netcdf-4.6.2-intelmpi-intel/lib
cm "env CC=icc CXX=icpc FC=ifort CFLAGS=$cflag CXXFLAGS=$cflag FFLAGS=$cflag FCFLAGS=$cflag ./configure --prefix=$td" "configure $pkg"
cm "make" "build $pkg"

# ================================================= check build
if [ $skipcheck -eq 0 ]; then
  echo Checking $pkg
  cm "make check" "$pkg"
fi

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
