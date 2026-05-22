cmake_minimum_required(VERSION 3.20)

# 目标系统基本信息
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CORE cortex-m0plus)

# 查找策略
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 创建工程
project(${PROJECT_NAME} C)

# 生成文件输入路径
set(LINKER_SCRIPT ${CMAKE_SOURCE_DIR}/.ti/generate/device_linker.lds)
set(GENLIBS_SCRIPT ${CMAKE_SOURCE_DIR}/.ti/generate/device.lds.genlibs)
set(OPT_SCRIPT ${CMAKE_SOURCE_DIR}/.ti/generate/device.opt)

# 输出路径
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/outputs)
set(HEX_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.hex) # 固件
set(MAP_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.map) # 内存分析
set(ELF_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.elf) # 可执行文件

# 源文件
file(GLOB_RECURSE SRC_FILES
    ${CMAKE_SOURCE_DIR}/Application/*.c
    ${CMAKE_SOURCE_DIR}/Core/*.c
)

# 创建可执行目标
add_executable(${PROJECT_NAME} ${SRC_FILES})
set_target_properties(${PROJECT_NAME} PROPERTIES
    SUFFIX ".elf"
)

# 头文件
target_include_directories(${PROJECT_NAME} PRIVATE
    # $ENV{ARM_GCC_ROOT}/arm-none-eabi/include/newlib-nano
    # $ENV{ARM_GCC_ROOT}/arm-none-eabi/include
    ${CMAKE_SOURCE_DIR}/Drivers/third_party/CMSIS/Core/Include
    ${CMAKE_SOURCE_DIR}/Drivers
    ${CMAKE_SOURCE_DIR}/Application/Driver
    ${CMAKE_SOURCE_DIR}/Core/Inc
)

# 编译
target_compile_options(${PROJECT_NAME} PRIVATE
    # 宏定义
    @${OPT_SCRIPT}

    # 目标与架构
    -mcpu=${CORE}
    -march=armv6-m
    -mthumb
    -mfloat-abi=soft

    # 语言
    -std=c99

    # 优化
    -ffunction-sections
    -fdata-sections

    # 调试与警告
    -g
    -gstrict-dwarf
    -Wall
)

# Debug/Release
if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    target_compile_options(${PROJECT_NAME} PRIVATE -O0)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Os)
endif()

# 链接
target_link_options(${PROJECT_NAME} PRIVATE
    # 基础控制
    -T${LINKER_SCRIPT}
    -T${GENLIBS_SCRIPT}
    -Wl,-Map=${MAP_FILE}

    # 目标与架构
    -march=armv6-m
    -mthumb

    # 行为控制
    -static
    -specs=nano.specs
    -specs=nosys.specs
    -Wl,--gc-sections

    # 调试与警告
    -Wl,--no-warn-rwx-segments
)

target_link_directories(${PROJECT_NAME} PRIVATE
    # $ENV{ARM_GCC_ROOT}/arm-none-eabi/lib/thumb/v6-m/nofp
    ${CMAKE_SOURCE_DIR}/Drivers/ti/driverlib/lib/gcc/m0p/mspm0g1x0x_g3x0x
    ${CMAKE_SOURCE_DIR}/Drivers
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    gcc
    c
    m
)

# 生成.hex文件
add_custom_command(
    TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex
        ${ELF_FILE}
        ${HEX_FILE}
)