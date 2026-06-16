# CMakeLists.txt - TI MSPM0
cmake_minimum_required(VERSION 3.28)

# 传播 TI_SDK_ROOT 到 try_compile 子项目 (CMake 3.24+)
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES TI_SDK_ROOT)

# 芯片选择 (通过 preset 或 -DCHIP=xxx 传入)
# 工具链文件按 toolchain_<CHIP>.cmake 命名放于 .cmake/toolchain/
if(NOT DEFINED CHIP)
    message(FATAL_ERROR "CHIP not set. Pass -DCHIP=xxx or set it in CMakePresets.json")
endif()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/.cmake/toolchain/toolchain_${CHIP}.cmake")
if(NOT EXISTS "${CMAKE_TOOLCHAIN_FILE}")
    message(FATAL_ERROR "Toolchain not found: ${CMAKE_TOOLCHAIN_FILE}\n"
                        "Create .cmake/toolchain/toolchain_${CHIP}.cmake or set CHIP to an existing one")
endif()
message(STATUS "CHIP: ${CHIP}")

# 项目定义
project(${PROJECT_NAME} C CXX ASM)

# 输出路径（build/output/）
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/output)
set(HEX_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.hex)
set(ELF_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.elf)
set(MAP_FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}.map)

# 源文件
file(GLOB_RECURSE SRC_FILES
    ${CMAKE_SOURCE_DIR}/User/*.c
    ${CMAKE_SOURCE_DIR}/User/*.cpp
    ${CMAKE_SOURCE_DIR}/Core/*.c
    ${CMAKE_SOURCE_DIR}/Core/*.cpp
)

add_executable(${PROJECT_NAME} ${SRC_FILES})
set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".elf")

# 头文件路径
target_include_directories(${PROJECT_NAME} PRIVATE
    ${TI_SDK_ROOT}/source/third_party/CMSIS/Core/Include
    ${TI_SDK_ROOT}/source
    ${CMAKE_SOURCE_DIR}/User
    ${CMAKE_SOURCE_DIR}/Core/Inc
)

# 编译选项（仅添加 SysConfig 响应文件中的宏定义）
# -mcpu / -mthumb / -ffunction-sections 等已由 toolchain 自动注入
target_compile_options(${PROJECT_NAME} PRIVATE
    @${OPT_SCRIPT}
)

# 链接选项
# -T 链接脚本 / -specs 等已由 toolchain 自动注入
target_link_options(${PROJECT_NAME} PRIVATE
    -Wl,-Map=${MAP_FILE}
)

# 从 SysConfig 生成的 device.lds.genlibs 读取并链接可用库
# 不存在的库会报错提示，需在 .syscfg 中关闭对应 genLib* 功能
include(${CMAKE_SOURCE_DIR}/.cmake/link_syscfg_libs.cmake)
link_syscfg_libs(${PROJECT_NAME} "${TI_SDK_ROOT}" "${CMAKE_SOURCE_DIR}/.ti/generate/device.lds.genlibs")

# ARM GCC 嵌入式运行时标准三件套
target_link_libraries(${PROJECT_NAME} PRIVATE
    gcc
    c
    m
)

# 后处理：生成 .hex 文件
add_custom_command(
    TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex ${ELF_FILE} ${HEX_FILE}
    COMMENT "Generating ${HEX_FILE}"
)

# 配置信息输出
message(STATUS "========================================")
message(STATUS "Project:        ${PROJECT_NAME}")
message(STATUS "Build Type:     ${CMAKE_BUILD_TYPE}")
message(STATUS "Toolchain:      ${CMAKE_TOOLCHAIN_FILE}")
message(STATUS "Core:           ${CORE}")
message(STATUS "Architecture:   ${ARCH}")
message(STATUS "Chip Family:    ${CHIP_FAMILY}")
message(STATUS "TI SDK:         ${TI_SDK_ROOT}")
message(STATUS "Output Dir:     ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "========================================")