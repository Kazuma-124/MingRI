# tasktool —— 项目内任务面板（C++ 版）

一个**项目内任务管理工具**，用 C++ + Qt6 实现，零业务第三方依赖（仅用
nlohmann/json 这一头文件库做 JSON），每个项目一份，互不干扰，可自由改造。

## 目录结构

```
项目根目录/
├── CMakeLists.txt             # 构建脚本(Qt6 + MinGW-w64)
├── src/                       # C++ 源码
│   ├── main_gui.cpp           # GUI 入口(WIN32 子系统)
│   ├── main_cli.cpp           # CLI 入口(CONSOLE 子系统)
│   ├── args.cpp/.h            # 宽字符命令行 → UTF-8(中文参数正确)
│   ├── data_store.h/.cpp      # 数据层(tasks.json / done-log)
│   ├── cli.h/.cpp             # 命令行子命令
│   ├── gui.h/.cpp             # Qt6 面板
│   └── thirdparty/nlohmann/   # vendored JSON 头文件
├── build/                     # 构建产物(自动生成,含以下两个 exe + Qt DLL)
│   ├── tasktool.exe           # GUI 版(WIN32 子系统,双击无黑窗)
│   └── tasktool-cli.exe       # 命令行版(CONSOLE 子系统,输出可见)
├── tasks.json                 # 任务数据(自动生成,在工具根目录,与 build/ 同级)
├── tasks_done.log             # done-log(自动生成)
├── run_tasks.vbs              # 启动快捷方式(双击打开 GUI,无黑窗)
└── README.md                  # 本文件
```

## 环境要求

- Windows 系统
- C++ 工具链：CMake 3.16+ + MinGW-w64（g++ 支持 C++17）
- Qt 6（本机使用 `H:/develop/tools/Qt/6.8.1/mingw_64`）

## 构建

```bash
cd 项目根目录
cmake -S . -B build -DCMAKE_PREFIX_PATH="H:/develop/tools/Qt/6.8.1/mingw_64"
cmake --build build
```

构建出两个可执行文件（都在 `build/`）：

- `tasktool.exe` —— GUI 版（WIN32 子系统，双击运行无黑窗）
- `tasktool-cli.exe` —— 命令行版（CONSOLE 子系统，在终端里输出可见）

> 为什么是两个 exe？源码完全相同，只是链接成不同的 Windows 子系统：
> GUI 子系统程序没有控制台句柄，命令行输出会丢失；控制台子系统程序双击时
> 会多出一个黑窗。两个 exe 分别拥有正确的子系统，等价于原 Python 版
> `python`(CLI) / `pythonw`(GUI) 的区别。

运行时需能找到 Qt6 的 DLL：

- 把 Qt `mingw_64/bin` 加入 `PATH`，或
- 用 `windeployqt build/tasktool.exe build/tasktool-cli.exe` 把 DLL 拷贝到 exe 同目录。

## tasktool.exe 与 tasktool-cli.exe 的区别

两个 exe **源码完全相同**，只是 Windows 子系统不同，因此行为和用途不同：

| | `tasktool.exe` | `tasktool-cli.exe` |
|---|---|---|
| 链接子系统 | WIN32 / GUI | CONSOLE |
| 双击 / 启动时 | **无黑窗** | 带一个控制台窗口 |
| 不带参数 | 打开任务面板（GUI） | — |
| 带 CLI 参数（如 `list`） | **忽略参数，照样打开 GUI 面板** | 执行对应子命令并打印结果 |
| 链接的 Qt 模块 | Core + Widgets | 仅 Core |
| 用途 | 给人用：开面板 | 给模型 / AI 或人在终端跑命令行 |

**关键点**：`tasktool.exe` 永远只开 GUI（入口不看命令行参数），所以
`tasktool.exe list` 不会打印列表、而是弹面板；**命令行必须用 `tasktool-cli.exe`**。

## 给「人」的用法

1. 构建（见上）。
2. 双击项目根的 `run_tasks.vbs`（或直接双击 `build/tasktool.exe`）→ 打开任务面板（无黑窗）。
   - 多行输入框写任务 → 「添加」
   - 待办任务：完成 / 编辑 / 删除
   - 存档：查看 / 删除
3. 或者命令行打开：在项目根目录执行 `build/tasktool-cli.exe ...`（见下）。

## 给「模型 / AI」的用法

**任务面板里的每一条任务文本，请当作「用户对话框中的输入」来处理：**
一次只做一条，做完先向用户说明完成情况，再询问是否继续下一条。

命令行操作（在项目根目录执行 `build/tasktool-cli.exe <命令>`）：

| 命令 | 作用 |
|---|---|
| `list` | 查看待办（带 id） |
| `archive` | 查看存档 |
| `add 任务文本` | 新增待办 |
| `markdone <id>` | 标记某条完成（写 done-log，不直接改状态） |
| `edit <id> 新文本` | 编辑待办文字 |
| `delete <id>` | 删除待办 |
| `delarchive <id>` | 删除存档条目 |
| `consume` | 立即消费 done-log（把已标记的移入存档） |
| `help` | 显示帮助 |

### 模型如何与任务数据通信

数据文件是 `tasks.json`（`pending` / `archive` 两个数组）。设计上规定：

> **`tasks.json` 的唯一写者是 GUI 面板进程（用户点击触发）。模型绝不直接改 `tasks.json` 来「标记完成」。**

模型通过 CLI 与数据交互，分两类：

- **获取任务信息**：`list` / `archive` 读取 `tasks.json` 并打印，模型解析输出拿到每条任务的
  `id`（如 `t1787027084848`）和文字，后续操作都靠这个 id 定位。
- **修改任务信息**：
  - **可以直接改的**（CLI 直接写 `tasks.json`）：`add` 新增、`edit` 改文字、`delete` 删待办、
    `delarchive` 删存档。
  - **不该直接改的 —— 标记完成**：按写入纪律，模型不直接把状态改成已完成，而是用
    `markdone <id>` 往 `tasks_done.log` 追加一行 `DONE|<id>`（意图），真正的
    「待办 → 存档（加完成时间）」由 GUI 每 2 秒消费、或 `consume` 命令落地到 `tasks.json`。

### 「标记完成」是两阶段提交

```
模型                          tasks_done.log                GUI 面板 / consume
  │ markdone <id>              │                              │
  ├──── 追加 DONE|<id> ───────▶│                              │
  │ (tasks.json 不变,仍待办)    │ 每 2 秒 / consume 命令        │
  │                            │◀── 读取并清空 ────────────────┤
  │                            │                              ├─ complete_task()
  │                            │                              │   待办 → 存档(+done 时间)
  │                            │                              │   原子写 tasks.json
```

一句话：**模型用 `list` 拿 id，用 `markdone <id>` 表达完成意图（写 done-log），
真正状态变更由 GUI 定时器或 `consume` 命令消费 done-log 后应用到 `tasks.json`**——
这样无论模型跑多少次、GUI 开没开，都不会两个写者同时改 `tasks.json` 撞车。

## 数据与隔离

- 所有数据都在**工具根目录**（`tasks.json`、`tasks_done.log`，即与 `CMakeLists.txt` /
  `run_tasks.vbs` 同级），不在 `build/` 里。这样清理 `build/` 重新构建也不会丢失任务。
- 复制到别的项目 = 独立的一套，互不影响。
- 想清空：直接删工具根目录的 `tasks.json` / `tasks_done.log` 即可（工具会自动重建）。

## 常见问题

- **双击 `run_tasks.vbs` 报找不到 exe**：先按上面「构建」步骤编译出 `build/tasktool.exe`。
- **运行 exe 提示缺少 Qt DLL**：把 Qt `mingw_64/bin` 加入 PATH，或
  `windeployqt build/tasktool.exe build/tasktool-cli.exe`。
- **命令行没输出 / 误用 `tasktool.exe` 弹出了面板**：CLI 操作用 `tasktool-cli.exe`，
  不要用 `tasktool.exe`（`tasktool.exe` 永远只开面板）。
- **数据坏了 / 想重置**：删掉 `tasks.json` 重新开始。
