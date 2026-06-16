# TI MSPM0 GCC + CMake + Ninja 嵌入式工程模板

基于 TI MSPM0 系列 MCU 的嵌入式 C 语言工程模板，使用 **GCC 交叉编译工具链** + **CMake** + **Ninja** 构建系统。

---

## 环境要求

| 工具 | 最低版本 | 说明 |
|---|---|---|
| arm-none-eabi-gcc | ≥ 15.2 | ARM GCC 交叉编译器（需加入系统环境） |
| CMake | ≥ 3.28 | 构建系统生成器 |
| Ninja | ≥ 1.13 | 高性能构建执行器 |
| TI MSPM0 SDK | ≥ 2.10 | 芯片驱动库及外设驱动 |
| SysConfig | ≥ 1.27 | TI 外设图形化配置工具 |

---

## 目录结构

```
.
├── .cmake/
│   ├── presets/
│   │   └── CMakePresets.json.template ← CMakePresets.json 模板
│   ├── toolchain/
│   │   └── toolchain.cmake.template   ← 芯片工具链定义
│   ├── user/
│   │   └── CMakeUserPresets.json.template ← CMakeUserPresets.json 模板
│   └── link_syscfg_libs.cmake ← 自动解析 SysConfig 生成的库依赖
│
├── .ti/
│   ├── TI-MSPM0-Template.syscfg ← SysConfig 外设配置文件
│   ├── syscfg.bat             ← SysConfig 一键生成脚本
│   └── generate/              ← SysConfig 生成的代码（gitignore）
│
├── Core/
│   ├── Inc/                   ← SysConfig 生成的头文件
│   ├── Src/                   ← SysConfig 生成的源文件
│   └── Startup/               ← 芯片启动文件
│
├── User/
├── .vscode/
│   ├── template
│   │   ├── settings.json.template ← settings.json 模板
│   │   └── c_cpp_properties.json.template ← c_cpp_properties.json 模板
│   ├── tasks.json             ← 一键构建任务链
│   ├── launch.json            ← 调试配置（待更新）
│   ├── settings.json          ← 工作区设置（用户个性化）
│   └── c_cpp_properties.json  ← IntelliSense 配置（用户个性化）
│
├── CMakePresets.json          ← CMake 预设（项目共用）
├── CMakeUserPresets.json      ← 用户本地配置（gitignore）
├── CMakeLists.txt             ← 顶层构建文件
└── README.md
```

---

## 快速开始

### 1. 安装工具链

确保 `arm-none-eabi-gcc` 已加入系统环境，验证：

```bash
arm-none-eabi-gcc --version
cmake --version
ninja --version
```

### 2. 配置 CMakeUserPresets.json

复制模板并填入你的 SDK 路径：

```bash
cp CMakeUserPresets.json.template CMakeUserPresets.json
```

编辑 `CMakeUserPresets.json`，将 `TI_SDK_ROOT` 指向你本地的 TI MSPM0 SDK。

### 3. 选择芯片

本项目支持多芯片切换。打开 `CMakePresets.json`，确认 `CHIP` 值：

```json
"CHIP": "mspm0g3507"
```

如需使用其他芯片，改为对应的芯片代号，并在 `.cmake/toolchain/` 下创建对应的 `toolchain_<CHIP>.cmake`。

### 4. 配置 VS Code IntelliSense（可选）

复制模板：

```bash
cp .vscode/c_cpp_properties.json.template .vscode/c_cpp_properties.json
cp .vscode/settings.json.template .vscode/settings.json
```

- `c_cpp_properties.json`：将 `myDeviceDefines` 改为你芯片对应的宏（如 `__MSPM0G3507__`）
- `settings.json`：根据你的环境修改 TI SDK 路径、SysConfig 路径、调试器路径等

### 5. 构建

**VS Code：** 按 `Ctrl+Shift+B` 一键构建（依次执行：SysConfig → CMake 配置 → 编译 → 生成 .hex）

**命令行：**

```bash
cmake --preset user-debug
cmake --build build
```

编译产物在 `build/output/` 下：
- `*.elf` — 可执行文件
- `*.hex` — 固件（用于烧录）
- `*.map` — 链接映射表（内存分析用）

---

## 芯片切换

通过 `CHIP` 变量选择目标芯片，工具链文件按 `toolchain_<CHIP>.cmake` 命名存放于 `.cmake/toolchain/`。

**切换方式：**

```bash
# 命令行
cmake -B build -G Ninja -DCHIP=mspm0g3507 -DTI_SDK_ROOT="..."

# 或在 CMakePresets.json / CMakeUserPresets.json 中设置
"CHIP": "mspm0g3507"
```

**添加新芯片：**

1. 在 `.cmake/toolchain/` 下创建 `toolchain_<chip>.cmake`，定义编译器、CPU 架构、链接脚本等
2. 可选：添加对应的 SysConfig `.syscfg` 文件
3. 设置 `CHIP` 变量为新芯片名即可

> 未设置 `CHIP` 时，配置阶段会报错提示，避免无默认值的隐式行为。

---

## CMake 架构

```
CMakePresets.json  ──── 项目级预设（生成器、构建目录、CHIP）
        +
CMakeUserPresets.json ── 用户级预设（TI_SDK_ROOT 等本地路径）
        │
        ▼
toolchain_<CHIP>.cmake ── 交叉编译环境（编译器、架构标志、链接脚本）
        │
        ▼
CMakeLists.txt  ───────── 源文件、头文件路径、链接库
        │
        ▼
link_syscfg_libs.cmake ── 解析 SysConfig 生成的 device.lds.genlibs，
                          自动检查并链接存在的库文件
```

**执行流程：**

```
cmake --preset user-debug
  ① 读取 CMakePresets.json + CMakeUserPresets.json → CHIP、TI_SDK_ROOT
  ② 加载 toolchain_<CHIP>.cmake → 编译器、架构、链接脚本
  ③ 执行 CMakeLists.txt → project() → 编译 → 链接 → .hex
```

---

## SysConfig

SysConfig 是 TI 的外设图形化配置工具，生成芯片初始化代码和链接脚本。

**用法：**

```bash
# 手动运行
.ti/syscfg.bat <工程目录> <.syscfg文件名> <SysConfig安装目录> <SDK目录>
```

**genLib\* 开关：**

在 `.syscfg` 文件中通过 `ProjectConfig.genLibXxx = true/false` 控制各中间件库的启用。

| 标志 | 说明 | GCC 兼容性 |
|---|---|---|
| `genLibDrivers` | TI Drivers 驱动库 | ✅ |
| `genLibIQ` | IQMath 定点数学库 | ✅ |
| `genLibGC` | GUI Composer 图形库 | ✅ |
| `genLibModbus` | Modbus 协议库 | ✅ |
| `genLibSMBUS` | SMBus 通信库 | ✅（注意编译器格式） |
| `genLibCMSIS` | CMSIS 头文件 | ✅（仅头文件） |
| `genLibGaugeL2` | 电池电量库 | ⚠️ 需确认 GCC 版本 |
| `genLibMC` | 电机控制库 | ❌ 无 GCC 预编译库 |

`link_syscfg_libs.cmake` 会自动解析 SysConfig 生成的 `device.lds.genlibs`，逐条检查库文件是否存在。存在则链接，不存在则报错提示用户在 `.syscfg` 中关闭对应功能。

---

## VS Code 集成

### 构建任务（tasks.json）

`Ctrl+Shift+B` 触发三级任务链：

```
SysConfig 生成 → CMake 配置 → 编译 + 链接 + .hex
```

### 个性化配置文件

项目采用模板分离用户个性化配置：

| 文件 | 用途 | 是否 gitignore | 模板 |
|---|---|---|---|
| `settings.json` | 工作区设置（SDK 路径、调试器路径等） | 否 | `settings.json.template` |
| `c_cpp_properties.json` | IntelliSense 配置（芯片宏定义、头文件路径） | 否 | `c_cpp_properties.json.template` |
| `CMakeUserPresets.json` | 用户 CMake 预设（`TI_SDK_ROOT`） | 是 | `CMakeUserPresets.json.template` |

使用流程：

1. 复制模板文件：`cp xxx.json.template xxx.json`
2. 根据你的环境修改其中的占位项（如 SDK 路径、芯片宏定义等）
3. `settings.json` 中的 `ti.device`、`ti.sysconfig.root`、`ti.sdk.root` 会被其他配置文件通过 `${config:ti.*}` 引用

### 调试配置（待更新）

`launch.json` 中的调试器配置（J-Link / OpenOCD）正在完善中。

---

## 常见问题

### CMake Tools 按钮配置失败

CMake Tools 扩展的 "Delete cache and reconfigure" 按钮可能不适用本项目的 preset 机制。
建议使用 `Ctrl+Shift+B`（基于 tasks.json 的构建任务），或命令行：

```bash
cmake --preset user-debug && cmake --build build
```

### 链接时报 ARM/Thumb 错误

确认 `toolchain_<CHIP>.cmake` 中包含了 `-mthumb` 标志，并且启动文件与应用程序编译模式一致。对于 Cortex-M 系列，所有代码必须为 Thumb 模式。

### 找不到 driverlib.a

确认 `CMakeUserPresets.json` 中的 `TI_SDK_ROOT` 指向正确的 SDK 路径。
`link_syscfg_libs.cmake` 会自动从 SysConfig 生成的配置中找到并链接 driverlib。
