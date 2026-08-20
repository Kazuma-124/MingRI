#pragma once
#include <string>
#include <vector>

// 从宽字符命令行获取 UTF-8 参数(保证中文正确)。
// args[0] 为程序路径,之后为实际参数。
std::vector<std::string> get_command_line_args_utf8();
