# .ti 文件夹
## 1. .syscfg 文件 - TI Sysconfig GUI 文件
运行方式：D:\Programs\DevTools\TI\Sysconfig\sysconfig_gui.bat
文件图标：在\HKEY_CLASSES_ROOT\syscfg_auto_file项下添加DefaultIcon子项，新建字符串值，数据是D:/Programs/DevTools/TI/Sysconfig/dist/sysconfig.ico

## 2. syscfg.bat 文件 - 编译 TI Sysconfig GUI
修改SYSCFG_PATH和SDK_ROOT路径
实现编译 TI Sysconfig GUI 文件，复制必要的文件到工程中
修改 .syscfg 文件后应立即运行此脚本，防止生成问题
运行该脚本的 task 已与 CMake build task 独立开，避免每次 CMake build 时都编译一次TI Sysconfig GUI

## 3. generate 文件夹
该文件夹下为TI Sysconfig GUI 编译生成的文件，可直接在CMakeLists中调用，无需解析文件

# .vscode 文件夹
## 1. settings.json - 编辑器行为与项目级设置
1. `Ctrl + Shift + P` 打开命令面板
2. 在命令面板中输入并选择 `Preferences: Open Settings (JSON)`

## 2. c_cpp_properties.json - C/C++ 插件的头文件与编译器配置
1. `Ctrl + Shift + P` 打开命令面板
2. 在命令面板中输入并选择 `Edit Configurations (JSON)`

## 3. tasks.json - 编译任务配置
1. `Ctrl + Shift + P` 打开命令面板
2. 在命令面板中输入并选择 `Tasks: Configure Task`

## 4. launch.json - 调试器运行配置
1. 进入 `运行与调试` 界面
2. 点击 `创建一个launch.json文件`

# CMake Tools 拓展
## 1. cmake-tools-kits.json - CMake 工具包配置文件
### 基础模板
### 1. ARM GCC（嵌入式开发）
```json
{
    "name": "ARM GCC",
    "compilers": {
      "C": "D:\\Programs\\Runtimes\\GCC\\arm-none-eabi\\bin\\arm-none-eabi-gcc.exe",
      "CXX": "D:\\Programs\\Runtimes\\GCC\\arm-none-eabi\\bin\\arm-none-eabi-g++.exe"
    },
    "isTrusted": true,
    "environmentVariables": {
      "CMT_ARM_GCC_PATH": "D:\\Programs\\Runtimes\\GCC\\arm-none-eabi\\bin"
    },
    "preferredGenerator": {
      "name": "Ninja"
    }
  }
```

# Drivers 文件夹
均对应SDK中的 source 文件夹

# GCC 编译与链接选项
## 1. 编译选项 (Compile Options)
**CMake 函数**：`target_compile_options()`
### 1. 基本控制
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-c` | 只编译不链接，生成 `.o` 文件 | |
| `-S` | 只编译不汇编，生成 `.s` 汇编文件 | |
| `-E` | 只预处理，不编译 | |
| `-o <file>` | 指定输出文件名 | |
| `-v` | 显示详细编译过程 | `-v`，调试用 |
| `-###` | 显示编译命令但不执行 | |
| `-pipe` | 使用管道而非临时文件加速编译 | |
| `-x <language>` | 指定源文件语言（`c`, `c++`, `assembler` 等） | |
| `@<file>` | 从文件中读取编译选项（响应文件） | `@${OPT_SCRIPT}` |
| `-save-temps` | 保存中间文件（`.i`, `.s`, `.o`） | |
| `-time` | 显示每个子进程的执行时间 | |

### 2. 目标与架构
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-mcpu=<name>` | 指定 CPU 型号 | `-mcpu=cortex-m0plus` |
| `-march=<name>` | 指定 ARM 架构 | `-march=armv6-m` |
| `-mthumb` | 生成 Thumb 指令集 | |
| `-marm` | 生成 ARM 指令集（Cortex-A） | |
| `-mfloat-abi=<name>` | 浮点调用约定：`soft` / `softfp` / `hard` | `-mfloat-abi=soft` |
| `-mfpu=<name>` | 指定 FPU 类型 | `-mfpu=fpv4-sp-d16` |
| `-m32` / `-m64` | 生成 32 位 / 64 位代码 | |
| `-mtune=<name>` | 针对特定 CPU 优化调度 | `-mtune=cortex-m4` |

### 3. 语言
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-std=<standard>` | 语言标准（`c99`, `c11`, `gnu99`, `c++11` 等） | `-std=c99` |
| `-ansi` | 等价于 `-std=c89` | |
| `-funsigned-char` | `char` 默认为无符号 | |
| `-fshort-enums` | 枚举用最小整数类型 | |
| `-fno-rtti` | 禁用 C++ RTTI | |
| `-fno-exceptions` | 禁用 C++ 异常 | |
| `-fno-common` | 将未初始化的全局变量放入 BSS | |
| `-trigraphs` | 支持三字符组 | |

### 4. 优化
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-O0` | 不优化，默认，调试最佳 | |
| `-O1` | 基本优化，平衡体积/速度 | |
| `-O2` | 推荐优化，启用多数不增体积的优化 | |
| `-O3` | 激进优化，可能显著增体积 | |
| `-Os` | 优化代码体积（推荐嵌入式） | |
| `-Oz` | 极致优化体积（Clang） | |
| `-Og` | 优化调试体验 | |
| `-ffunction-sections` | 每个函数放入独立段 | |
| `-fdata-sections` | 每个数据放入独立段 | |
| `-flto` | 链接时优化 | |
| `-fomit-frame-pointer` | 省略帧指针 | |
| `-fPIC` / `-fpic` | 生成位置无关代码（共享库） | |
| `-fvisibility=hidden` | 隐藏符号（减小体积） | |

### 5. 调试与警告
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-g` | 生成调试信息 | |
| `-ggdb` | 生成 GDB 专用调试信息 | |
| `-gdwarf-<version>` | 指定 DWARF 版本 | |
| `-g3` | 包含宏定义的调试信息 | |
| `-Wall` | 开启常见警告 | |
| `-Wextra` | 开启额外警告 | |
| `-Werror` | 警告视为错误 | |
| `-w` | 关闭所有警告 | |
| `-pedantic` | 严格遵循标准警告 | |
| `-Wno-unused-function` | 抑制未使用函数警告 | |

## 2. 链接选项 (Link Options)
**CMake 函数**：`target_link_options()`
### 1. 基本控制
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-o <file>` | 输出文件名 | |
| `-T <file>` | 指定链接脚本 | `-T${LINKER_SCRIPT}` |
| `-Wl,-Map=<file>` | 生成 map 文件 | `-Wl,-Map=${MAP_FILE}` |
| `-Wl,<option>` | 将选项传递给链接器 | `-Wl,--gc-sections` |
| `-Xlinker <option>` | 同 `-Wl,`，但一次只能传一个 | |
| `-v` | 显示详细链接过程 | |

### 2. 目标与架构
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-mcpu=<name>` | CPU 型号（与编译一致） | `-mcpu=cortex-m0plus` |
| `-march=<name>` | ARM 架构（与编译一致） | `-march=armv6-m` |
| `-mthumb` | Thumb 指令集（与编译一致） | `-mthumb` |

### 3. 行为控制
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-static` | 静态链接（嵌入式默认） | |
| `-shared` | 生成共享库 | |
| `-nostartfiles` | 不使用标准启动文件 | |
| `-nostdlib` | 不使用标准库和启动文件 | |
| `-nodefaultlibs` | 不使用默认库 | |
| `--specs=<file>.specs` | 指定 C 库规格 | `--specs=nano.specs` |
| `-Wl,--gc-sections` | 删除未使用的段 | |
| `-Wl,--start-group` ... `--end-group` | 解决循环依赖 | |
| `-Wl,--whole-archive` ... `--no-whole-archive` | 强制链接整个库 | |
| `-Wl,-Bstatic` / `-Wl,-Bdynamic` | 切换静态/动态链接 | |
| `-u <symbol>` | 强制包含某符号 | |
| `-Wl,--defsym,<symbol>=<value>` | 定义符号值 | |
| `--entry=<symbol>` | 指定入口点 | |
| `-Wl,-rpath=<path>` | 设置运行时库搜索路径 | |

### 4. 调试与警告
| GCC 选项 | 说明 | 示例 |
| :--- | :--- | :--- |
| `-Wl,--no-warn-rwx-segments` | 禁用 RWX 段警告 | |
| `-Wl,--verbose` | 详细链接过程 | |
| `-Wl,--print-gc-sections` | 打印被删除的段 | |
| `-Wl,--cref` | 输出交叉引用表 | |
| `--fatal-warnings` | 警告视为错误 | |


## 三、CMake 函数接管对照表
| GCC 选项 | CMake 函数 | 示例 |
| :--- | :--- | :--- |
| `-I<dir>` | `target_include_directories()` | `target_include_directories(${PROJECT_NAME} PRIVATE ./inc)` |
| `-D<macro>[=value]` | `target_compile_definitions()` | `target_compile_definitions(${PROJECT_NAME} PRIVATE __MSPM0G3507__)` |
| `-L<path>` | `target_link_directories()` | `target_link_directories(${PROJECT_NAME} PRIVATE /path/to/libs)` |
| `-l<name>` | `target_link_libraries()` | `target_link_libraries(${PROJECT_NAME} PRIVATE driverlib)` |
| `-l:filename.a` | `target_link_libraries()` + 完整路径 | `target_link_libraries(${PROJECT_NAME} PRIVATE /path/to/driverlib.a)` |