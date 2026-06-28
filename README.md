# TI MSPM0 通用工程模板

这是一个面向 TI MSPM0 系列 MCU 的通用嵌入式工程模板，集成了：

- TI SysConfig 外设配置与代码生成
- 多编译器支持：Arm GNU Toolchain (`arm-none-eabi-gcc`)、TI Arm Clang (`tiarmclang`)、Clang/LLVM
- CMake + Ninja 构建系统
- VS Code IntelliSense、构建任务与 Cortex-Debug 调试
- OpenOCD 烧录与调试
- DAPLink、J-Link 和 XDS110 调试器配置
- 根据芯片型号自动选择架构、启动文件和 DriverLib

首次克隆工程后，只需运行一次配置脚本并填写本机工具路径，即可完成代码生成、编译、烧录和调试。

## 工作流程

```text
configure.bat
    ↓
选择编译器 (GCC / Clang / TIClang) → 选择调试器 (GDB / LLDB)
    ↓
生成本机配置、CMake Preset、工具链和 VS Code 配置
    ↓
syscfg.bat
    ↓
SysConfig 根据编译器类型生成外设代码、链接脚本和库依赖
    ↓
CMake + Ninja
    ↓
生成 ELF、HEX 和 MAP
    ↓
OpenOCD + 调试器
    ↓
烧录并进入源码调试
```

## 环境要求

| 工具 | 作用 | 必需 |
| --- | --- | --- |
| TI SysConfig | 生成外设初始化代码和链接配置 | ✅ |
| TI MSPM0 SDK | 提供设备头文件、DriverLib 和启动文件 | ✅ |
| 编译器 (GCC / TIClang / Clang) | 编译和链接 | ✅ (至少一个) |
| 调试器 (GDB / LLDB) | 调试 | ✅ (至少一个) |
| CMake 3.28+ | 生成构建系统 | ✅ |
| Ninja | 执行构建 | ✅ |
| OpenOCD | 烧录并提供 GDB Server | ✅ |
| VS Code (可选) | 编辑、构建和图形化调试 | 推荐 |

### 编译器支持状态

| 编译器 | 状态 | 说明 |
| --- | --- | --- |
| GCC (`arm-none-eabi-gcc`) | ✅ 已验证 | 编译、烧录、GDB 调试通过 |
| TIClang (`tiarmclang`) | ✅ 已验证 | 编译、烧录、GDB 调试通过 |
| Clang/LLVM | ⚠️ 实验性 | 模板已配置，待完整验证 |

### 调试器兼容性

| 调试器 | OpenOCD 烧录 | 说明 |
| --- | --- | --- |
| XDS110 | ✅ 可用 | 可直接通过 OpenOCD 正常烧录 |
| DAPLink / CMSIS-DAP | ✅ 可用 | 可直接通过 SWD 正常烧录 |
| J-Link | ✅ 可用，需调整驱动 | 使用 OpenOCD 前通常需要将 J-Link USB 接口更换为 WinUSB 或 libusb 兼容驱动 |

如果使用 VS Code，建议安装：

- C/C++
- CMake Tools
- Cortex-Debug

安装后可在终端检查基础工具：

```powershell
cmake --version
ninja --version
```

Arm GCC、TIClang、Clang 和 OpenOCD 不要求加入系统 `PATH`，配置脚本会记录它们的安装路径。

## 目录结构

```text
.
├─ .cmake/
│  ├─ template/                     CMake 配置模板 (gcc/clang/ticlang)
│  ├─ toolchain/                    生成的本机工具链文件
│  └─ utils/                        SysConfig 库解析工具
├─ .ti/
│  ├─ TI-MSPM0-Template.syscfg      SysConfig 工程
│  ├─ syscfg.bat                    SysConfig 代码生成脚本 (Windows)
│  ├─ syscfg.sh                     SysConfig 代码生成脚本 (Linux/Mac)
│  └─ generate/                     SysConfig 中间生成文件
├─ .vscode/
│  ├─ template/                     VS Code 配置模板
│  ├─ openocd_daplink.cfg           DAPLink 配置
│  ├─ openocd_jlink.cfg             J-Link 配置
│  └─ openocd_xds110.cfg            XDS110 配置
├─ Core/
│  ├─ Inc/                          SysConfig 生成的头文件
│  ├─ Src/                          SysConfig 生成的源文件
│  └─ Startup/                     对应芯片的启动文件
├─ User/                            用户应用代码
├─ scripts/
│  ├─ configure.bat                 首次配置脚本 (Windows)
│  ├─ configure.sh                  首次配置脚本 (Linux/Mac)
│  ├─ config.ini                    生成的本机配置
│  └─ mspm0_chip_db.csv            芯片参数数据库
├─ CMakeLists.txt
├─ CMakePresets.json                生成的项目级 Preset
└─ CMakeUserPresets.json            生成的本机路径 Preset
```

## 快速开始

下面的流程假设工程已经从 Git 克隆到本地。

### 1. 运行配置脚本

在工程根目录打开 PowerShell：

```powershell
.\scripts\configure.bat
```

首次运行时选择重新配置：

```text
Do you want to reconfigure? (Y/N)[default: Y]: 直接回车或输入 Y
```

随后依次输入本机安装路径和选择编译器/调试器：

```text
TI Sysconfig path:              D:\Tommy\DevTools\TI\Sysconfig
TI MSPM0 SDK path:              D:\Tommy\DevTools\TI\mspm0_sdk_2_10_00_04
Select compiler:
  [1] GCC ARM (default)
  [2] Clang/LLVM
  [3] TIClang
Enter choice [1]:               1 (GCC) 或 3 (TIClang)
```

根据选择的编译器，输入对应路径：

```text
# GCC
GCC path:                       D:\Tommy\Runtimes\C-C++\Arm\arm-none-eabi-15.2

# TIClang
TIClang path:                   D:\Tommy\Runtimes\C-C++\Arm\ticlang-5.1

# Clang
Clang/LLVM path:                D:\Tommy\Runtimes\C-C++\Arm\LLVM-Arm-19.1
Use GCC as link driver? (Y/N): Y (推荐，使用 GCC 链接器)
```

选择调试器：

```text
Select debugger:
  [1] GDB (default)
  [2] LLDB
Enter choice [1]:               1
```

最后输入 OpenOCD 路径和芯片型号：

```text
OpenOCD path:                   D:\Tommy\DevTools\OpenOCD
Enter chip model:               mspm0g3507
```

路径既可以使用 `\`，也可以使用 `/`。脚本会自动将路径转换为工程配置所需的格式。

芯片型号不区分大小写，但必须存在于 [`scripts/mspm0_chip_db.csv`](scripts/mspm0_chip_db.csv) 中。

配置脚本会自动完成：

1. 生成 `CMakePresets.json`
2. 生成 `CMakeUserPresets.json`
3. 根据编译器类型生成 `.cmake/toolchain/toolchain.cmake`
4. 生成 `scripts/config.ini`
5. 从 TI SDK 复制对应芯片和编译器的启动文件

当脚本询问是否生成 VS Code 配置时，推荐输入 `Y`：

```text
Do you want to generate VS Code configuration? (Y/N)[default: Y]: Y
```

随后会生成：

- `.vscode/c_cpp_properties.json` — IntelliSense 配置 (含 GCC/Clang/TIClang + PATH fallback)
- `.vscode/launch.json` — 调试配置 (DAPLink/J-Link/XDS110, 跨平台 `openocd`)
- `.vscode/tasks.json` — 构建任务 (跨平台, Windows 默认 `.bat`, Linux/Mac 预留 `.sh`)

> **注意**：这些文件包含本机绝对路径，默认不会提交到 Git。

### 2. 运行 SysConfig

在工程根目录执行：

```powershell
.\.ti\syscfg.bat
```

脚本会调用 TI SysConfig CLI，根据当前编译器类型生成对应的文件：

**GCC / Clang 输出：**
```text
.ti/generate/device_linker.lds    (GNU 格式链接脚本)
.ti/generate/device.lds.genlibs   (库依赖)
```

**TIClang 输出：**
```text
.ti/generate/device_linker.cmd    (TI 格式链接命令文件)
.ti/generate/device.cmd.genlibs   (库依赖)
```

**通用输出：**
```text
Core/Src/ti_msp_dl_config.c
Core/Inc/ti_msp_dl_config.h
.ti/generate/device.opt
```

看到下面的输出表示生成成功：

```text
SysConfig Complete!
```

### 3. 配置 CMake

```powershell
# Debug 构建
cmake --preset user-debug

# Release 构建
cmake --preset user-release
```

配置成功后，构建文件位于 `build/`。

### 4. 编译工程

```powershell
cmake --build build
```

构建产物位于：

```text
build/outputs/<工程目录名>.elf
build/outputs/<工程目录名>.hex
build/outputs/<工程目录名>.map
```

裸机工程使用 `nosys.specs` (GCC) 或等效配置时，链接器可能提示 `_read`、`_write`、`_close` 或 `_lseek` 未实现。如果工程没有使用对应的标准输入输出功能，这些警告不影响固件生成。

## 使用 VS Code 一键构建

完成首次配置后，在 VS Code 中按：

```text
Ctrl + Shift + B
```

默认的 `CMake build` 任务会依次执行：

```text
TI Sysconfig Prebuild
    ↓
CMake configure
    ↓
CMake build
```

也可以通过"终端 → 运行任务"单独执行：

- `Project Configure`
- `TI Sysconfig Prebuild`
- `CMake configure`
- `CMake build`
- `CMake clean`
- `CMake reconfigure`
- `CMake clean rebuild`
- `Flash (XDS110)`
- `Flash (DAPLink)`
- `Flash (J-Link)`

## 烧录与调试

### 使用 XDS110 烧录

XDS110 已经过实际烧录验证。连接目标板后，在 VS Code 中运行：

```text
Flash (XDS110)
```

或在工程根目录手动执行：

```powershell
& "D:\Tommy\DevTools\OpenOCD\bin\openocd" `
  -s "D:\Tommy\DevTools\OpenOCD\openocd\scripts" `
  -f ".vscode\openocd_xds110.cfg" `
  -c "program build/outputs/TI-MSPM0-Template.elf verify reset exit"
```

### 使用 DAPLink 烧录

连接 DAPLink 与目标板，确认 SWDIO、SWCLK、GND 和目标板供电连接正确。在 VS Code 中运行：

```text
Flash (DAPLink)
```

### 使用 J-Link 烧录

模板包含 J-Link 的 OpenOCD 配置 (`.vscode/openocd_jlink.cfg`)。但 Windows 默认安装的 SEGGER J-Link 驱动通常不能被 OpenOCD 的 `libusb` 接口直接使用。使用前可能需要通过 USBDriverTool 或 Zadig 将 J-Link USB 接口驱动更换为 WinUSB 或 libusbK。

> 更换驱动后 SEGGER 官方工具可能无法识别设备，需要使用官方工具时请恢复原驱动。

### 调试

1. 连接调试器和目标板
2. 确认工程已经成功编译
3. 打开 VS Code"运行和调试"面板
4. 选择 `Debug (XDS110)` （或其他调试器）
5. 按 `F5`

调试配置会启动 OpenOCD、连接 GDB、下载 ELF，并运行到 `main`。成功后可以设置断点、单步执行、查看变量、寄存器、调用栈和内存。

## 更换芯片 / 编译器

重新运行：

```powershell
.\scripts\configure.bat
```

选择 `Y` 重新配置。脚本会根据 `scripts/mspm0_chip_db.csv` 自动更新所有相关配置。

更换芯片或编译器后应清理旧构建：

```powershell
rm -r -force build
.\.ti\syscfg.bat
cmake --preset user-debug
cmake --build build
```

## 修改外设配置

使用 TI SysConfig 打开 `.ti\TI-MSPM0-Template.syscfg`，修改引脚、时钟或外设后保存文件，再运行：

```powershell
.\.ti\syscfg.bat
cmake --build build
```

不要直接长期修改 `Core/Src/ti_msp_dl_config.c` 或 `Core/Inc/ti_msp_dl_config.h`，因为再次运行 SysConfig 时这些文件会被重新生成。用户自己的业务代码建议放在 `User/` 目录。

## 跨平台说明

模板设计支持 Windows、Linux 和 macOS，但当前仅在 **Windows** 上完成完整验证。

- `scripts/configure.bat` — Windows 配置脚本 ✅
- `scripts/configure.sh` — Linux/Mac 配置脚本 (待实现)
- `.ti/syscfg.bat` — Windows SysConfig 脚本 ✅
- `.ti/syscfg.sh` — Linux/Mac SysConfig 脚本 (待实现)
- `launch.json` — `openocd` 路径已去除 `.exe` 后缀，跨平台通用
- `tasks.json` — 默认 `.bat`，Linux/Mac 覆盖 `.sh` (预留)
- `c_cpp_properties.json` — 每个编译器提供 Win32/Mac/Linux 三平台配置 + PATH fallback

## 常见问题

### `config.ini not found`

尚未完成首次配置。运行 `.\scripts\configure.bat`。

### 找不到 `sysconfig_cli.bat`

填写的 SysConfig 路径不正确。确认填写的是 TI Sysconfig 根目录。

### 找不到 `.metadata\product.json`

TI MSPM0 SDK 路径不正确，或者 SDK 安装不完整。

### 找不到编译器 (arm-none-eabi-gcc / tiarmclang)

检查对应编译器安装目录中是否存在 `bin\` 子目录和对应的可执行文件，然后重新运行配置脚本。GCC 路径填写安装根目录即可，脚本会自动拼接 `bin/arm-none-eabi-gcc.exe`。

### CMake 找不到 DriverLib

确认 TI SDK 路径正确，并先运行 `.\.ti\syscfg.bat`。模板会读取 `.ti/generate/` 下的 genlibs 文件并自动链接 SysConfig 请求的库。

### OpenOCD 找不到调试器

检查调试器是否已连接电脑、USB 驱动是否正常、调试器是否被其他程序占用、SWD 接线是否正确、目标板是否供电。

### GCC 切换 TIClang 后 GCC_ROOT 未清除

重新运行配置脚本并选择 TIClang，脚本会自动清除 GCC_ROOT（v1.1+）。如果 config.ini 中仍有残留，手动编辑或重新配置即可。

## 已验证配置

本模板已经使用以下组合完成实际验证：

| 项目 | 详情 |
| --- | --- |
| 芯片 | MSPM0G3507 |
| SDK | TI MSPM0 SDK 2.10.00.04 |
| 编译器 | GCC 15.2 ✅ / TIClang 5.1 ✅ / Clang ⚠️ |
| 调试器 | GDB ✅ / LLDB ⚠️ |
| 构建系统 | CMake 3.28+ + Ninja |
| 烧录工具 | OpenOCD |
| 调试接口 | XDS110 ✅ / DAPLink ✅ / J-Link ✅ (需驱动调整) |
| 平台 | Windows ✅ / Linux ⚠️ / macOS ⚠️ |

验证内容：SysConfig 代码生成 → CMake 配置 → 编译链接 → ELF/HEX 生成 → OpenOCD 烧录校验 → GDB 调试 (断点、单步)

## 许可

MIT License
