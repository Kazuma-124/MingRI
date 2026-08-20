#pragma once
#include <string>
#include <vector>

// 一条任务。done 为空字符串表示仍在待办；非空表示完成时间(已归档)。
struct Task {
    std::string id;
    std::string text;
    std::string created;
    std::string done;
};

namespace datastore {

// 数据文件(tasks.json / tasks_done.log)所在目录,默认 = 可执行文件所在目录,
// 等价于 Python 版的 __file__ 目录。可通过 set_base_dir 覆盖(主要用于测试)。
void set_base_dir(const std::string& dir);
std::string base_dir();

// 路径访问(供 CLI/GUI 调试使用)
std::string tasks_file_path();
std::string done_log_path();

// 读取任务存储;文件缺失/损坏则返回两份空列表。
bool load_tasks(std::vector<Task>& pending, std::vector<Task>& archive);

// 原子写(先临时文件再替换),避免写到一半被读。
bool save_tasks(const std::vector<Task>& pending, const std::vector<Task>& archive);

// 新增待办,返回新任务 id(失败返回空串)。
std::string add_task(const std::string& text);

// 把待办移入存档(加 done 时间),返回是否成功。
bool complete_task(const std::string& tid);

// 编辑待办文字,返回是否成功。
bool edit_pending(const std::string& tid, const std::string& new_text);

// 删除待办 / 删除存档条目。
void delete_pending(const std::string& tid);
void delete_archive(const std::string& tid);

// AI 单向追加 DONE|<id> 到 done-log(不触碰 tasks.json),由 GUI/consume 归档。
void append_done_log(const std::string& tid);

// 读取并消费 done-log,把可归档的待办移入存档;返回已归档的 id 列表。
std::vector<std::string> consume_done_log();

}  // namespace datastore
