// main_cli.cpp —— CLI 入口(链接为 CONSOLE 子系统,命令行输出可见)
#include "cli.h"
#include "args.h"

#include <windows.h>
#include <QCoreApplication>

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    // 控制台 UTF-8 输出(无控制台时失败也无碍)
    SetConsoleOutputCP(65001);
    auto args = get_command_line_args_utf8();
    return cli_run(args);
}
