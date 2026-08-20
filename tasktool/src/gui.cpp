// gui.cpp —— Qt6 Widgets 面板(等价 Python 版 tasktool.py 的 GUI 部分)
//
// 布局: 顶部标题栏(说明按钮) + 待办区 + 新任务区 + 存档区。
// 每 2 秒消费 done-log 并刷新,以把 AI 标记的 DONE|<id> 自动归档。
//
// 注: 本类未使用 Q_OBJECT / slots,connect 全部用新语法(成员函数指针),
// 因此无需 moc 处理;但 CMake 仍开启 AUTOMOC 以备后续扩展。

#include "gui.h"
#include "data_store.h"

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QScrollArea>
#include <QPushButton>
#include <QLabel>
#include <QTextEdit>
#include <QMessageBox>
#include <QTimer>
#include <QDialog>
#include <QFont>
#include <QApplication>
#include <QSizePolicy>

class TaskPanel : public QWidget {
public:
    explicit TaskPanel(QWidget* parent = nullptr) : QWidget(parent) {
        setWindowTitle("tasktool 任务面板");
        resize(740, 540);
        setMinimumSize(540, 440);

        auto* root = new QVBoxLayout(this);
        root->setContentsMargins(8, 4, 8, 8);

        // ---- 顶部标题栏 ----
        auto* header = new QHBoxLayout();
        auto* title = new QLabel("tasktool 任务面板");
        QFont tf = title->font();
        tf.setPointSize(11);
        title->setFont(tf);
        header->addWidget(title);
        auto* helpBtn = new QPushButton("说明");
        helpBtn->setFixedWidth(60);
        connect(helpBtn, &QPushButton::clicked, this, &TaskPanel::showHelp);
        header->addWidget(helpBtn);
        root->addLayout(header);

        // ---- 待办区 ----
        auto* pendingBox = new QGroupBox("待办");
        auto* pendingV = new QVBoxLayout(pendingBox);
        pendingScroll_ = new QScrollArea();
        pendingScroll_->setWidgetResizable(true);
        pendingContent_ = new QWidget();
        pendingContent_->setLayout(new QVBoxLayout(pendingContent_));
        pendingContent_->layout()->setAlignment(Qt::AlignTop);
        pendingScroll_->setWidget(pendingContent_);
        pendingV->addWidget(pendingScroll_);
        root->addWidget(pendingBox, 5);

        // ---- 新任务区 ----
        auto* addBox = new QGroupBox("新任务");
        auto* addH = new QHBoxLayout(addBox);
        taskText_ = new QTextEdit();
        taskText_->setFixedHeight(80);
        taskText_->setPlaceholderText(QString::fromUtf8("写任务,支持多行..."));
        auto* addBtn = new QPushButton("添加");
        addBtn->setFixedWidth(70);
        connect(addBtn, &QPushButton::clicked, this, &TaskPanel::onAdd);
        addH->addWidget(taskText_, 1);
        addH->addWidget(addBtn, 0, Qt::AlignTop);
        root->addWidget(addBox, 0);

        // ---- 存档区 ----
        auto* archiveBox = new QGroupBox(QString::fromUtf8("存档（已完成）"));
        auto* archiveV = new QVBoxLayout(archiveBox);
        archiveScroll_ = new QScrollArea();
        archiveScroll_->setWidgetResizable(true);
        archiveContent_ = new QWidget();
        archiveContent_->setLayout(new QVBoxLayout(archiveContent_));
        archiveContent_->layout()->setAlignment(Qt::AlignTop);
        archiveScroll_->setWidget(archiveContent_);
        archiveV->addWidget(archiveScroll_);
        root->addWidget(archiveBox, 2);

        refresh();
        scheduleConsume();
    }

private:
    void showHelp() {
        QMessageBox::information(
            this, QString::fromUtf8("使用说明"),
            QString::fromUtf8(
                "tasktool:每个项目独立的任务面板。\n\n"
                "• 添加：在下面多行输入框写任务,点「添加」进待办。\n"
                "• 完成：待办点「完成」会归档(加完成时间)。\n"
                "• 编辑：待办点「编辑」可修改文字。\n"
                "• 删除：待办/存档都可点「删除」彻底移除。\n"
                "• AI 只读：AI 完成一条后只向 tasks_done.log 追加 DONE|<id>,\n"
                "  由面板自动归档,AI 不直接改写 tasks.json。\n\n"
                "命令行用法见 tasktool/README.md。"));
    }

    void onAdd() {
        QString t = taskText_->toPlainText().trimmed();
        if (t.isEmpty()) return;
        datastore::add_task(t.toStdString());
        taskText_->clear();
        refresh();
    }

    void onEdit(const std::string& tid, const std::string& oldText) {
        QDialog dlg(this);
        dlg.setWindowTitle(QString::fromUtf8("编辑任务"));
        dlg.resize(520, 180);
        dlg.setMinimumSize(360, 140);
        auto* v = new QVBoxLayout(&dlg);
        auto* te = new QTextEdit(QString::fromStdString(oldText));
        v->addWidget(te);
        auto* save = new QPushButton(QString::fromUtf8("保存"));
        v->addWidget(save, 0, Qt::AlignCenter);
        QObject::connect(save, &QPushButton::clicked, [&]() {
            QString nv = te->toPlainText().trimmed();
            if (nv.isEmpty()) {
                QMessageBox::warning(&dlg, QString::fromUtf8("提示"),
                                     QString::fromUtf8("任务内容不能为空。"));
                return;
            }
            datastore::edit_pending(tid, nv.toStdString());
            dlg.accept();
            refresh();
        });
        dlg.exec();
    }

    void scheduleConsume() {
        if (!datastore::consume_done_log().empty()) refresh();
        QTimer::singleShot(2000, this, &TaskPanel::scheduleConsume);
    }

    void refresh() {
        std::vector<Task> p, a;
        datastore::load_tasks(p, a);
        fill(pendingContent_, p, false);
        fill(archiveContent_, a, true);
    }

    void fill(QWidget* content, const std::vector<Task>& items, bool done) {
        QLayout* lay = content->layout();
        QLayoutItem* child;
        while ((child = lay->takeAt(0)) != nullptr) {
            delete child->widget();
            delete child;
        }
        if (items.empty()) {
            auto* lbl = new QLabel(QString::fromUtf8("(空)"));
            lbl->setStyleSheet("color: gray;");
            lay->addWidget(lbl);
            return;
        }
        for (const auto& it : items) {
            auto* rowW = new QWidget();
            auto* h = new QHBoxLayout(rowW);
            h->setContentsMargins(4, 2, 4, 2);

            auto* txt = new QLabel(QString::fromStdString(it.text));
            txt->setWordWrap(true);
            txt->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
            h->addWidget(txt, 1);

            if (done) {
                auto* dt = new QLabel(QString::fromStdString(it.done));
                dt->setStyleSheet("color: gray;");
                h->addWidget(dt);
                auto* del = new QPushButton(QString::fromUtf8("删除"));
                del->setFixedWidth(50);
                connect(del, &QPushButton::clicked, this, [this, id = it.id]() {
                    datastore::delete_archive(id);
                    refresh();
                });
                h->addWidget(del);
            } else {
                auto* comp = new QPushButton(QString::fromUtf8("完成"));
                comp->setFixedWidth(50);
                connect(comp, &QPushButton::clicked, this, [this, id = it.id]() {
                    datastore::complete_task(id);
                    refresh();
                });
                auto* edit = new QPushButton(QString::fromUtf8("编辑"));
                edit->setFixedWidth(50);
                connect(edit, &QPushButton::clicked, this,
                        [this, id = it.id, text = it.text]() { onEdit(id, text); });
                auto* del = new QPushButton(QString::fromUtf8("删除"));
                del->setFixedWidth(50);
                connect(del, &QPushButton::clicked, this, [this, id = it.id]() {
                    datastore::delete_pending(id);
                    refresh();
                });
                h->addWidget(comp);
                h->addWidget(edit);
                h->addWidget(del);
            }
            lay->addWidget(rowW);
        }
    }

    QScrollArea* pendingScroll_ = nullptr;
    QScrollArea* archiveScroll_ = nullptr;
    QWidget* pendingContent_ = nullptr;
    QWidget* archiveContent_ = nullptr;
    QTextEdit* taskText_ = nullptr;
};

int run_gui() {
    QApplication::setFont(QFont("Microsoft YaHei UI", 9));
    TaskPanel w;
    w.show();
    return QApplication::exec();
}
