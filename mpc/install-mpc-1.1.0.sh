#!/bin/bash

####{{{ parameter

# package name and its version
pkg=mpc-1.1.0
src=mpc-1.1.0

# url of source code
url=https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz

# name of downloaded file
zip=mpc-1.1.0.tar.gz

# target directory
td=$HOME/.pkg/$pkg

# script path
sp=$HOME/.script/env-$pkg.sh

# environment script
env="\
  export LD_LIBRARY_PATH=$td/lib:\$LD_LIBRARY_PATH \
  export CPATH=$td/include:\$CPATH \
"

# ramdisk path
ramdisk=/tmp/ramdisk-$pkg

# scripts of required packages
required=" \
  $HOME/.script/env-gmp-6.1.2.sh \
  $HOME/.script/env-mpfr-4.0.1.sh \
"

# environment variable
gmpLib=$HOME/.pkg/gmp-6.1.2/lib
mpfrLib=$HOME/.pkg/mpfr-4.0.1/lib

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
rm -rf log

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
cm "./configure --prefix=$td --with-gmp-lib=$gmpLib --with-mpfr-lib=$mpfrLib" "configure $pkg"
cm "make -j" "build $pkg"
cm "make check" "build $src"

# ================================================= install
echo Installing $pkg
cm "make install" "install $src"

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
