cmake_minimum_required(VERSION 3.16)
project(tasktool CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Qt6 通过 CMAKE_PREFIX_PATH 提供,例如:
#   cmake -S . -B build -DCMAKE_PREFIX_PATH="H:/develop/tools/Qt/6.8.1/mingw_64"
find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

# 同一套源码产出两个可执行文件:
#   tasktool.exe     -> WIN32/GUI 子系统(双击/由 vbs 启动,无黑窗)
#   tasktool-cli.exe -> CONSOLE 子系统(命令行,输出在任意终端可见)
# 这样 CLI 与 GUI 各自拥有正确的子系统(等价 Python 版 python / pythonw 的区别)。

add_executable(tasktool WIN32
    src/main_gui.cpp
    src/data_store.cpp
    src/cli.cpp
    src/gui.cpp
    src/args.cpp
)
target_include_directories(tasktool PRIVATE src src/thirdparty)
target_link_libraries(tasktool PRIVATE Qt6::Core Qt6::Widgets)

add_executable(tasktool-cli
    src/main_cli.cpp
    src/data_store.cpp
    src/cli.cpp
    src/args.cpp
)
target_include_directories(tasktool-cli PRIVATE src src/thirdparty)
target_link_libraries(tasktool-cli PRIVATE Qt6::Core)
