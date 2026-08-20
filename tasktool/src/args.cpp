// args.cpp —— 从宽字符命令行取 UTF-8 参数
// Windows 控制台传来的窄字符串是本地编码(GBK),中文会乱码;
// 用 CommandLineToArgvW 取 UTF-16 再转 UTF-8 可正确保留中文。

#include "args.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>

#include <string>
#include <vector>

static std::string wchar_to_utf8(const wchar_t* w) {
    int sz = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (sz <= 0) return std::string();
    std::string out(sz - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, &out[0], sz, nullptr, nullptr);
    return out;
}

std::vector<std::string> get_command_line_args_utf8() {
    std::vector<std::string> args;
    int wargc = 0;
    wchar_t** wargv = CommandLineToArgvW(GetCommandLineW(), &wargc);
    if (wargv) {
        for (int i = 0; i < wargc; ++i) args.push_back(wchar_to_utf8(wargv[i]));
        LocalFree(wargv);
    }
    return args;
}
