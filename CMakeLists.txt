cmake_minimum_required(VERSION 3.15)

project(dtc_build)

set(CMAKE_C_STANDARD 17)

set(dtc_srcs_dir "${CMAKE_SOURCE_DIR}/dtc")
set(libfdt_srcs_dir "${dtc_srcs_dir}/libfdt")
set(libufdt_srcs_dir "${CMAKE_SOURCE_DIR}/libufdt")
set(mkdtimg_srcs_dir "${libufdt_srcs_dir}/utils/src")

#get dtc version from Android.bp
execute_process(
        COMMAND bash -c "echo $(sed -f ${dtc_srcs_dir}/METADATA_version.sed -n ${dtc_srcs_dir}/METADATA)"
        OUTPUT_VARIABLE dtc_version
        OUTPUT_STRIP_TRAILING_WHITESPACE
)
message("dtc version: ${dtc_version}")
set(VCS_TAG "${dtc_version}-Android-build")
configure_file("${CMAKE_SOURCE_DIR}/dtc/version_gen.h.in" 
                "${CMAKE_SOURCE_DIR}/dtc/version_gen.h"
)

include_directories(
        ${dtc_srcs_dir}
        ${mkdtimg_srcs_dir}
        ${libfdt_srcs_dir}
        ${libufdt_srcs_dir}/include
        ${libufdt_srcs_dir}/sysdeps/include
)

set(dt_cflags
        "-Wall"
        "-Wno-macro-redefined"
        "-Wno-missing-field-initializers"
        "-Wno-sign-compare"
        "-Wno-unused-parameter"
        "-DNO_YAML"
)

set(libfdt_srcs
        "${libfdt_srcs_dir}/fdt.c"
        "${libfdt_srcs_dir}/fdt_check.c"
        "${libfdt_srcs_dir}/fdt_ro.c"
        "${libfdt_srcs_dir}/fdt_wip.c"
        "${libfdt_srcs_dir}/fdt_sw.c"
        "${libfdt_srcs_dir}/fdt_rw.c"
        "${libfdt_srcs_dir}/fdt_strerror.c"
        "${libfdt_srcs_dir}/fdt_empty_tree.c"
        "${libfdt_srcs_dir}/fdt_addresses.c"
        "${libfdt_srcs_dir}/fdt_overlay.c"
        "${libfdt_srcs_dir}/acpi.c"
)


set(libufdt_sysdeps_srcs
        "${libufdt_srcs_dir}/sysdeps/libufdt_sysdeps_posix.c"
)

set(dtc_srcs
        "${dtc_srcs_dir}/checks.c"
        "${dtc_srcs_dir}/data.c"
        "${dtc_srcs_dir}/dtc.c"
        "${dtc_srcs_dir}/dtc-lexer.c"
        "${dtc_srcs_dir}/dtc-parser.c"
        "${dtc_srcs_dir}/flattree.c"
        "${dtc_srcs_dir}/fstree.c"
        "${dtc_srcs_dir}/livetree.c"
        "${dtc_srcs_dir}/srcpos.c"
        "${dtc_srcs_dir}/treesource.c"
        "${dtc_srcs_dir}/util.c"
)

set(mkdtimg_srcs
        "${mkdtimg_srcs_dir}/mkdtimg.c"
        "${mkdtimg_srcs_dir}/mkdtimg_cfg_create.c"
        "${mkdtimg_srcs_dir}/mkdtimg_core.c"
        "${mkdtimg_srcs_dir}/mkdtimg_create.c"
        "${mkdtimg_srcs_dir}/mkdtimg_dump.c"
        "${mkdtimg_srcs_dir}/dt_table.c"
)

set(fdtget_srcs
        "${dtc_srcs_dir}/fdtget.c"
        "${dtc_srcs_dir}/util.c"
)

set(fdtput_srcs
        "${dtc_srcs_dir}/fdtput.c"
        "${dtc_srcs_dir}/util.c"
)

set(fdtdump_srcs
        "${dtc_srcs_dir}/fdtdump.c"
        "${dtc_srcs_dir}/util.c"
)

set(fdtoverlay_srcs
        "${dtc_srcs_dir}/fdtoverlay.c"
        "${dtc_srcs_dir}/util.c"
)

if (CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options("-Os")
        if(CMAKE_C_COMPILER_ID MATCHES "Clang")
                add_compile_options("-flto")
                add_link_options("-flto")
        endif()
        add_link_options("-Wl--gc-sections" "-s")
endif()
add_link_options("-static")

add_compile_options(${dt_cflags})
add_library(fdt STATIC ${libfdt_srcs})
add_library(ufdt_sysdeps STATIC ${libufdt_sysdeps_srcs})

#bins
add_executable(dtc ${dtc_srcs})
add_executable(mkdtimg ${mkdtimg_srcs})
add_executable(fdtget ${fdtget_srcs})
add_executable(fdtput ${fdtput_srcs})
add_executable(fdtdump ${fdtdump_srcs})
add_executable(fdtoverlay ${fdtoverlay_srcs})

target_link_libraries(dtc PRIVATE fdt)
target_link_libraries(fdtget PRIVATE fdt)
target_link_libraries(fdtput PRIVATE fdt)
target_link_libraries(fdtdump PRIVATE fdt)
target_link_libraries(fdtoverlay PRIVATE fdt)
target_link_libraries(mkdtimg PRIVATE fdt ufdt_sysdeps)