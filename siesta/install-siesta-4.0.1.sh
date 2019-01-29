#!/bin/bash

####{{{ parameter

# package name and its version
pkg=siesta-4.0.1
src=siesta-4.0.1

# url of source code
url=https://launchpad.net/siesta/4.0/4.0.1/+download/siesta-4.0.1.tar.gz

# name of downloaded file
zip=siesta-4.0.1.tar.gz

# target directory
td=$HOME/.pkg/$pkg

# script path
sp=$HOME/.script/env-$pkg.sh

# environment script
env="\
  export PATH=$td/bin:\$PATH \
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
  $HOME/.script/env-netcdf-fortran-4.4.4.sh \
  $HOME/.script/env-openmpi-3.1.0.sh \
"

# library directory
lapack_lib=$HOME/.pkg/lapack-3.8.0/lib64/liblapack.a
scalapack_lib=$HOME/.pkg/scalapack-2.0.2/lib/libscalapack.a
openblas_lib=$HOME/.pkg/openblas-0.2.20/lib/libopenblas.a
netcdff_root=$HOME/.pkg/netcdf-fortran-4.4.4
netcdf_root=$HOME/.pkg/netcdf-4.6.1
hdf5_root=$HOME/.pkg/hdf5-1.10.2

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
  rm -rf $pkg $src $sp $zip $td ~/$pkg.log $ramdisk
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
cd $src/Obj
cm "sh ../Src/obj_setup.sh" "setup $pkg"
cm "../Src/configure --prefix=$td --enable-mpi --with-scalapack=$scalapack_lib --with-blas=$openblas_lib --with-lapack=$lapack_lib" "configure $pkg"
mv arch.make make1
cat make1 | \
  sed "42c NETCDF_LIBS=-L$netcdff_root/lib" | \
  sed "43c NETCDF_INTERFACE=$netcdff_root/include/netcdf.mod" > make2
cat make2 > arch.make
echo "LIBS += -L$netcdff_root/lib -L$netcdf_root/lib -L$hdf5_root/lib -lnetcdff -lnetcdf -lhdf5_fortran -lhdf5 -lz" >> arch.make
cm "make" "build $pkg"

# ================================================= install
echo Installing $pkg
cp -r $ramdisk/$src $td
mkdir $td/bin
ln -s $td/Obj/siesta $td/bin/siesta

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
