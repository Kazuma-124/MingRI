// cli.cpp —— 命令行层(等价 Python 版 tasktool.py 的 CLI 部分)
//
// 子命令与 Python 版一一对应:
//   list / archive / add / markdone / edit / delete / delarchive / consume / help
// 写入纪律与 Python 版一致: markdone 只向 done-log 追加 DONE|<id>,
// 由 GUI 的定时器或 `consume` 命令消费归档。

#include "cli.h"
#include "data_store.h"

#include <iostream>

namespace {

void print_tasks(const std::vector<Task>& items, const std::string& title) {
    std::cout << title << "(" << items.size() << "):\n";
    if (items.empty()) {
        std::cout << "  (空)\n";
        return;
    }
    for (const auto& t : items) {
        std::string suffix = t.done.empty() ? "" : ("  [完成 " + t.done + "]");
        std::cout << "  " << t.id << "  " << t.text << suffix << "\n";
    }
}

int show_help() {
    std::cout <<
        "tasktool 任务面板命令行\n"
        "  用法: tasktool <子命令> [参数]\n\n"
        "  子命令:\n"
        "    list                列出待办(带 id)\n"
        "    archive             列出存档\n"
        "    add <任务文本>       新增一条待办\n"
        "    markdone <id>       标记完成(写入 done-log,由 GUI 自动归档)\n"
        "    edit <id> <新文本>   编辑待办文字\n"
        "    delete <id>         删除待办\n"
        "    delarchive <id>     删除存档条目\n"
        "    consume             立即消费 done-log(归档)\n"
        "    help                显示本帮助\n";
    return 0;
}

}  // namespace

int cli_run(const std::vector<std::string>& args) {
    std::string cmd = (args.size() > 1) ? args[1] : "help";
    // 子命令之后的参数
    std::vector<std::string> a(args.begin() + (args.size() > 1 ? 2 : 1), args.end());

    if (cmd == "list") {
        std::vector<Task> p, ar;
        datastore::load_tasks(p, ar);
        print_tasks(p, "待办");
        return 0;
    } else if (cmd == "archive") {
        std::vector<Task> p, ar;
        datastore::load_tasks(p, ar);
        print_tasks(ar, "存档");
        return 0;
    } else if (cmd == "add") {
        std::string text;
        for (size_t i = 0; i < a.size(); ++i) {
            if (i) text += " ";
            text += a[i];
        }
        if (text.empty()) {
            std::cout << "❌ 任务文本不能为空\n";
            return 1;
        }
        std::string tid = datastore::add_task(text);
        std::cout << "✅ 已新增任务 " << tid << "\n";
        return 0;
    } else if (cmd == "markdone") {
        if (a.empty()) {
            std::cout << "❌ 用法: tasktool markdone <id>\n";
            return 1;
        }
        datastore::append_done_log(a[0]);
        std::cout << "⏳ 已标记 " << a[0] << " 完成(done-log 已写入,GUI 打开时会自动归档)\n";
        return 0;
    } else if (cmd == "edit") {
        if (a.size() < 2) {
            std::cout << "❌ 用法: tasktool edit <id> <新文本>\n";
            return 1;
        }
        std::string new_text;
        for (size_t i = 1; i < a.size(); ++i) {
            if (i > 1) new_text += " ";
            new_text += a[i];
        }
        if (datastore::edit_pending(a[0], new_text))
            std::cout << "✅ 已编辑 " << a[0] << "\n";
        else
            std::cout << "❌ 找不到待办 " << a[0] << "\n";
        return 0;
    } else if (cmd == "delete") {
        if (a.empty()) {
            std::cout << "❌ 用法: tasktool delete <id>\n";
            return 1;
        }
        datastore::delete_pending(a[0]);
        std::cout << "✅ 已删除待办 " << a[0] << "\n";
        return 0;
    } else if (cmd == "delarchive") {
        if (a.empty()) {
            std::cout << "❌ 用法: tasktool delarchive <id>\n";
            return 1;
        }
        datastore::delete_archive(a[0]);
        std::cout << "✅ 已删除存档 " << a[0] << "\n";
        return 0;
    } else if (cmd == "consume") {
        auto done = datastore::consume_done_log();
        std::cout << "✅ 消费 done-log,归档 " << done.size() << " 条:";
        for (const auto& d : done) std::cout << " " << d;
        std::cout << "\n";
        return 0;
    } else {
        return show_help();
    }
}
