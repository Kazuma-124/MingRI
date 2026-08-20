// main_gui.cpp —— GUI 入口(链接为 WIN32/GUI 子系统,双击无黑窗)
#include "gui.h"
#include <QApplication>

int main(int argc, char** argv) {
    QApplication app(argc, argv);
    return run_gui();
}
