// data_store.cpp —— 数据层(等价 Python 版 tasktool.py 的"数据层")
//
// 设计要点:
//   * 数据文件位置 = 可执行文件所在目录(等价 __file__ 目录),保证"工具与数据同目录"。
//   * tasks.json 用 nlohmann/json 读写;dump(2,' ',false) 关闭 unicode 转义,
//     以匹配原 Python 的 ensure_ascii=False(中文人类可读)。
//   * 原子写用 QSaveFile(等价 os.replace 的原子语义)。
//   * done-log 协议 DONE|<id> 与原版完全一致。

#include "data_store.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <nlohmann/json.hpp>
#include <QFile>
#include <QSaveFile>
#include <QByteArray>
#include <QString>

#include <chrono>
#include <ctime>
#include <sstream>
#include <iomanip>
#include <cctype>

using json = nlohmann::json;

namespace {

std::string g_base;  // 缓存的基目录

std::string wchar_to_utf8(const wchar_t* w) {
    int sz = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (sz <= 0) return std::string();
    std::string out(sz - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, &out[0], sz, nullptr, nullptr);
    return out;
}

std::string exe_dir() {
    wchar_t buf[MAX_PATH] = {0};
    DWORD n = GetModuleFileNameW(nullptr, buf, MAX_PATH);
    std::string path = wchar_to_utf8(buf);
    if (n == 0 || path.empty()) return ".";
    auto pos = path.find_last_of("/\\");
    return (pos == std::string::npos) ? "." : path.substr(0, pos);
}

std::string trim(const std::string& s) {
    size_t a = 0, b = s.size();
    while (a < b && std::isspace((unsigned char)s[a])) ++a;
    while (b > a && std::isspace((unsigned char)s[b - 1])) --b;
    return s.substr(a, b - a);
}

std::string now_str() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
    localtime_s(&tm, &t);
    std::ostringstream ss;
    ss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
    return ss.str();
}

Task to_task(const json& o) {
    Task t;
    if (o.is_object()) {
        if (o.contains("id")) t.id = o.value("id", "");
        if (o.contains("text")) t.text = o.value("text", "");
        if (o.contains("created")) t.created = o.value("created", "");
        if (o.contains("done")) t.done = o.value("done", "");
    }
    return t;
}

json to_json(const Task& t) {
    json o;
    o["id"] = t.id;
    o["text"] = t.text;
    o["created"] = t.created;
    if (!t.done.empty()) o["done"] = t.done;
    return o;
}

}  // namespace

namespace datastore {

void set_base_dir(const std::string& dir) { g_base = dir; }

std::string base_dir() {
    if (g_base.empty()) {
        std::string d = exe_dir();
        // 若 exe 处于构建子目录(build/bin)内,把数据放到其父目录(工具根),
        // 避免清理 build 时误删 tasks.json —— 对齐原 Python 版"数据在实现同目录"的设计。
        std::string leaf = d.substr(d.find_last_of("/\\") + 1);
        if (leaf == "build" || leaf == "Build" || leaf == "bin" || leaf == "Bin")
            d = d.substr(0, d.find_last_of("/\\"));
        g_base = d;
    }
    return g_base;
}

std::string tasks_file_path() { return base_dir() + "/tasks.json"; }
std::string done_log_path() { return base_dir() + "/tasks_done.log"; }

bool load_tasks(std::vector<Task>& pending, std::vector<Task>& archive) {
    pending.clear();
    archive.clear();
    QFile f(QString::fromUtf8(tasks_file_path().c_str()));
    if (!f.exists()) return true;
    if (!f.open(QIODevice::ReadOnly)) return true;
    QByteArray ba = f.readAll();
    f.close();
    json j;
    try {
        j = json::parse(ba.begin(), ba.end(), nullptr, true);
    } catch (...) {
        return true;  // 损坏视为空
    }
    if (!j.is_object()) return true;
    if (j.contains("pending") && j["pending"].is_array())
        for (auto& e : j["pending"]) pending.push_back(to_task(e));
    if (j.contains("archive") && j["archive"].is_array())
        for (auto& e : j["archive"]) archive.push_back(to_task(e));
    return true;
}

bool save_tasks(const std::vector<Task>& pending, const std::vector<Task>& archive) {
    json j;
    j["pending"] = json::array();
    j["archive"] = json::array();
    for (auto& t : pending) j["pending"].push_back(to_json(t));
    for (auto& t : archive) j["archive"].push_back(to_json(t));
    std::string s = j.dump(2, ' ', false);
    QSaveFile sf(QString::fromUtf8(tasks_file_path().c_str()));
    if (!sf.open(QIODevice::WriteOnly)) return false;
    sf.write(QByteArray(s.data(), (int)s.size()));
    return sf.commit();
}

std::string add_task(const std::string& text) {
    std::string t = trim(text);
    if (t.empty()) return "";
    std::vector<Task> p, a;
    load_tasks(p, a);
    Task nt;
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                  std::chrono::system_clock::now().time_since_epoch())
                  .count();
    nt.id = "t" + std::to_string(ms);
    nt.text = t;
    nt.created = now_str();
    p.push_back(nt);
    save_tasks(p, a);
    return nt.id;
}

bool complete_task(const std::string& tid) {
    std::vector<Task> p, a;
    load_tasks(p, a);
    for (size_t i = 0; i < p.size(); ++i) {
        if (p[i].id == tid) {
            Task t = p[i];
            t.done = now_str();
            a.push_back(t);
            p.erase(p.begin() + i);
            save_tasks(p, a);
            return true;
        }
    }
    return false;
}

bool edit_pending(const std::string& tid, const std::string& new_text) {
    std::string nt = trim(new_text);
    if (nt.empty()) return false;
    std::vector<Task> p, a;
    load_tasks(p, a);
    for (auto& t : p) {
        if (t.id == tid) {
            t.text = nt;
            save_tasks(p, a);
            return true;
        }
    }
    return false;
}

void delete_pending(const std::string& tid) {
    std::vector<Task> p, a;
    load_tasks(p, a);
    std::vector<Task> np;
    for (auto& t : p)
        if (t.id != tid) np.push_back(t);
    p.swap(np);
    save_tasks(p, a);
}

void delete_archive(const std::string& tid) {
    std::vector<Task> p, a;
    load_tasks(p, a);
    std::vector<Task> na;
    for (auto& t : a)
        if (t.id != tid) na.push_back(t);
    a.swap(na);
    save_tasks(p, a);
}

void append_done_log(const std::string& tid) {
    QFile f(QString::fromUtf8(done_log_path().c_str()));
    f.open(QIODevice::Append | QIODevice::WriteOnly);
    f.write(QByteArray("DONE|" + tid + "\n"));
    f.close();
}

std::vector<std::string> consume_done_log() {
    std::vector<std::string> done;
    QString path = QString::fromUtf8(done_log_path().c_str());
    QFile f(path);
    if (!f.exists()) return done;
    if (!f.open(QIODevice::ReadOnly)) return done;
    QByteArray raw = f.readAll();
    f.close();

    // 先清空,再处理:处理期间新追加的行落到新文件,不丢失(等价 Python 版逻辑)。
    {
        QSaveFile sf(path);
        if (sf.open(QIODevice::WriteOnly)) sf.commit();
    }

    QString content = QString::fromUtf8(raw);
    QStringList lines = content.split('\n', Qt::SkipEmptyParts);
    for (const QString& ln : lines) {
        QString s = ln.trimmed();
        if (s.startsWith("DONE|")) {
            QString tid = s.mid(5);
            if (complete_task(tid.toStdString())) done.push_back(tid.toStdString());
        }
    }
    return done;
}

}  // namespace datastore
