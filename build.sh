#!/bin/bash
LOCALDIR=$(pwd)
cc="clang"
cxx="clang++"

function check_msys_clang64_environment() {
    if uname -o | grep -qo "Msys"; then
        if [[ $cc == "clang" && $cxx == "clang++" && $MSYSTEM != "CLANG64" ]]; then
            echo "nedd to use Msys2 clang64 environment"
            exit 1
        fi
    fi
}

function install_deps() {
    if grep -qo "debian" /etc/os-release; then
        sudo apt install -y cmake gcc clang build-essential binutils nasm llvm lld libc++-dev libc++abi-dev ninja-build git wget flex bison zip unzip
    fi

    if uname -o | grep -qo "Msys"; then
        pacman -Sy --noconfirm
        pacman -S --needed --noconfirm pactoys git unzip wget flex bison zip unzip
        if [[ $MSYSTEM == "CLANG64" ]]; then
            pacboy -S --needed --noconfirm {clang,llvm,llvm-libs,libc++,lld,nasm,cmake,ninja}:p
        else
            pacboy -S --needed --noconfirm {gcc,llvm,llvm-libs,lld,nasm,cmake,ninja}:p
        fi
    fi
}



function build() {
    if [[ $1 == "android" ]]; then
        export PATH="$LOCALDIR/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
        cc="aarch64-linux-android$2-$cc"
    elif uname | grep -qo "Linux"; then
        export PATH="$LOCALDIR/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
    fi

    cd dtc
    rm  dtc-lexer.c dtc-parser.c dtc-parser.h
    flex -o dtc-lexer.c dtc-lexer.l
    bison -d -o dtc-parser.c dtc-parser.y
    cd ..
    rm -rf "build"
    echo "cmake -DCMAKE_C_COMPILER=$cc -G Ninja"
    cmake -DCMAKE_C_COMPILER=$cc -DCMAKE_BUILD_TYPE="Release" -G "Ninja" -B "build" || exit 1
    cmake --build "build" -j$(nproc --all) || exit 1
}

function install() {
    mkdir -p "build/bin" "build/lib"
    cd "build"
    [[ -e "dtc" ]] && mv "dtc" "bin"
    [[ -e "mkdtimg" ]] && mv "mkdtimg" "bin"
    [[ -e "fdtget" ]] && mv "fdtget" "bin"
    [[ -e "fdtput" ]] && mv "fdtput" "bin"
    [[ -e "fdtdump" ]] && mv "fdtdump" "bin"
    [[ -e "fdtoverlay" ]] && mv "fdtoverlay" "bin"
    if ls | grep -qo ".a"; then
        mv *.a lib
    fi
    if ls | grep -qo ".so"; then
        mv *.so lib
    fi
    cd $LOCALDIR
}

install_deps
check_msys_clang64_environment
build $@
install
