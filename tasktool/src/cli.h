#pragma once
#include <string>
#include <vector>

// CLI 入口。args[0] 为程序路径,args[1] 为子命令,其后为参数。
// 所有字符串均为 UTF-8(由 main 从宽字符命令行转换得到,保证中文正确)。
int cli_run(const std::vector<std::string>& args);
