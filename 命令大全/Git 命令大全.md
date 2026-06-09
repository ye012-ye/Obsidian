---
title: Git 命令大全
aliases:
  - git命令大全
  - Git 常用命令
tags:
  - 命令大全
  - Git
  - 版本控制
updated: 2026-04-12
---

# Git 命令大全

> [!info]
> 本文按日常开发流程整理 Git 常用命令，覆盖仓库初始化、提交、分支、合并、远程、回退、标签、stash、子模块与常用排障命令。
> 命令默认在 Git 仓库目录中执行，可配合 [[Linux 命令大全]] 一起查阅。

> [!warning]
> `git reset --hard`、`git clean -fd`、`git push --force` 会直接改写历史或删除文件。
> 执行前建议先运行 `git status`、`git log --oneline --decorate -n 10`、`git branch --show-current` 确认上下文。


### 主流前缀分类

| 前缀                          | 英文全称 / 含义          | 使用时机                        | 示例（推荐写法）                                                               |
| --------------------------- | ------------------ | --------------------------- | ---------------------------------------------------------------------- |
| `feature/`                  | 新功能、特性开发           | 正常迭代新增功能                    | `feature/user-profile-page`  <br>`feature/JIRA-456-payment-gateway`    |
| `bugfix/`                   | 普通 bug 修复（开发/测试阶段） | 非紧急 bug，开发或 staging 环境发现    | `bugfix/cart-total-miscalculation`  <br>`bugfix/PROJ-789-null-check`   |
| `hotfix/`                   | 紧急生产环境修复           | 已上线版本的严重问题（影响用户/收入/安全）      | `hotfix/security-token-leak-2026-01`  <br>`hotfix/payment-fail-urgent` |
| `release/`                  | 准备发布的版本分支          | 冻结功能，只修小 bug、改文案、打 tag      | `release/v2.3.1`  <br>`release/2026-q1-stable`                         |
| `refactor/`                 | 重构（不改功能，只改结构/性能）   | 改善代码可读性、性能、架构               | `refactor/user-service-cleanup`                                        |
| `docs/`                     | 纯文档变更              | README、API doc、注释、CHANGELOG | `docs/api-reference-update`                                            |
| `chore/`                    | 杂务、维护类（不影响生产代码）    | 更新依赖、改 CI 配置、改 .gitignore   | `chore/upgrade-node-20`  <br>`chore/remove-unused-deps`                |
| `test/`                     | 纯测试相关              | 新增/改测试用例，不动业务代码             | `test/integration/payment-flow`                                        |
| `experiment/`  <br>`spike/` | 实验、调研、技术验证         | 不确定是否合入主干的尝试                | `experiment/new-ai-search`                                             |
| `wip/`                      | 正在进行中（临时）          | 还没做完、不想 push、给自己占位          | `wip/payment-redesign`                                                 |

## 一、仓库初始化与配置

| 命令 | 描述 | 示例 |
|------|------|------|
| `git init` | 初始化本地仓库 | `git init` |
| `git clone` | 克隆远程仓库到本地 | `git clone https://github.com/user/repo.git` |
| `git clone -b <branch> --single-branch` | 只克隆指定分支 | `git clone -b dev --single-branch repo-url` |
| `git config --global user.name` | 配置全局用户名 | `git config --global user.name "zhangsan"` |
| `git config --global user.email` | 配置全局邮箱 | `git config --global user.email "a@b.com"` |
| `git config --list` | 查看当前生效配置 | `git config --list` |
| `git config --global core.editor` | 设置默认编辑器 | `git config --global core.editor "vim"` |
| `git config --global alias.st status` | 配置命令别名 | `git config --global alias.co checkout` |
| `git remote -v` | 查看远程仓库地址 | `git remote -v` |

## 二、工作区、暂存区与提交

| 命令                            | 描述                   | 示例                                         |
| ----------------------------- | -------------------- | ------------------------------------------ |
| `git status`                  | 查看工作区和暂存区状态          | `git status`                               |
| `git status -sb`              | 简洁显示分支和变更摘要          | `git status -sb`                           |
| `git add <file>`              | 添加指定文件到暂存区           | `git add app.py`                           |
| `git add .`                   | 添加当前目录所有变更           | `git add .`                                |
| `git add -p`                  | 按 hunk 交互式选择暂存       | `git add -p`                               |
| `git restore <file>`          | 丢弃工作区对某文件的修改         | `git restore app.py`                       |
| `git restore --staged <file>` | 把文件从暂存区撤回到工作区        | `git restore --staged app.py`              |
| `git rm <file>`               | 删除文件并加入暂存区           | `git rm old.txt`                           |
| `git mv <old> <new>`          | 重命名文件                | `git mv a.txt b.txt`                       |
| `git commit -m`               | 提交暂存区内容              | `git commit -m "fix: handle null value"`   |
| `git commit -am`              | 跳过 `add`，直接提交已跟踪文件修改 | `git commit -am "refactor: simplify flow"` |
| `git commit --amend`          | 修改最近一次提交             | `git commit --amend --no-edit`             |

### 提交类型建议

| 类型 | 含义 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: add login page` |
| `fix` | 修复问题 | `fix: handle timeout retry` |
| `refactor` | 重构，不改行为 | `refactor: split parser module` |
| `docs` | 文档修改 | `docs: update README` |
| `test` | 测试相关 | `test: add service unit tests` |
| `chore` | 杂项维护 | `chore: bump dependencies` |

## 三、查看差异与历史

| 命令                                           | 描述                  | 示例                                           |
| -------------------------------------------- | ------------------- | -------------------------------------------- |
| `git diff`                                   | 查看工作区相对暂存区的差异       | `git diff`                                   |
| `git diff --staged`                          | 查看暂存区相对上次提交的差异      | `git diff --staged`                          |
| `git diff branch1..branch2`                  | 比较两个分支内容差异          | `git diff main..feature/login`               |
| `git log`                                    | 查看提交历史              | `git log`                                    |
| `git log --oneline --graph --decorate --all` | 图形化查看简洁历史           | `git log --oneline --graph --decorate --all` |
| `git show <commit>`                          | 查看某次提交的详细内容         | `git show HEAD~1`                            |
| `git blame <file>`                           | 查看文件每行最后修改者         | `git blame src/main.py`                      |
| `git reflog`                                 | 查看 HEAD 变化记录，用于找回提交 | `git reflog`                                 |
| `git grep <pattern>`                         | 在版本库中搜索文本           | `git grep "TODO"`                            |
| `git shortlog -sn`                           | 按提交数统计贡献者           | `git shortlog -sn`                           |

## 四、分支管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `git branch` | 查看本地分支 | `git branch` |
| `git branch -a` | 查看本地和远程分支 | `git branch -a` |
| `git branch <name>` | 创建新分支 | `git branch feature/login` |
| `git switch <name>` | 切换到已有分支 | `git switch main` |
| `git switch -c <name>` | 创建并切换新分支 | `git switch -c feature/login` |
| `git checkout <name>` | 老写法，切换分支 | `git checkout dev` |
| `git checkout -b <name>` | 老写法，创建并切换分支 | `git checkout -b hotfix/api` |
| `git branch -m <new>` | 重命名当前分支 | `git branch -m feature/auth` |
| `git branch -d <name>` | 删除已合并分支 | `git branch -d feature/login` |
| `git branch -D <name>` | 强制删除分支 | `git branch -D feature/login` |
| `git branch --show-current` | 显示当前所在分支 | `git branch --show-current` |

## 五、合并、变基与拣选提交

| 命令                           | 描述               | 示例                                |
| ---------------------------- | ---------------- | --------------------------------- |
| `git merge <branch>`         | 把目标分支合并到当前分支     | `git merge feature/login`         |
| `git merge --no-ff <branch>` | 保留合并提交           | `git merge --no-ff feature/login` |
| `git rebase <branch>`        | 把当前分支变基到目标分支之上   | `git rebase main`                 |
| `git rebase -i <commit>`     | 交互式整理提交历史        | `git rebase -i HEAD~5`            |
| `git cherry-pick <commit>`   | 拣选某次提交到当前分支      | `git cherry-pick abc1234`         |
| `git merge --abort`          | 放弃当前 merge       | `git merge --abort`               |
| `git rebase --abort`         | 放弃当前 rebase      | `git rebase --abort`              |
| `git rebase --continue`      | 处理冲突后继续 rebase   | `git rebase --continue`           |
| `git cherry-pick --abort`    | 放弃当前 cherry-pick | `git cherry-pick --abort`         |

### 什么时候用 `merge`，什么时候用 `rebase`

| 场景 | 推荐 | 原因 |
|------|------|------|
| 团队协作分支合并到主干 | `merge` | 历史真实、风险较低 |
| 本地整理个人提交历史 | `rebase -i` | 历史更线性、提交更干净 |
| 已推送且多人共享的分支 | 谨慎 `rebase` | 会改写历史，容易影响他人 |

## 六、远程仓库操作

| 命令 | 描述 | 示例 |
|------|------|------|
| `git remote add origin <url>` | 添加远程仓库 | `git remote add origin git@github.com:user/repo.git` |
| `git remote set-url origin <url>` | 修改远程地址 | `git remote set-url origin git@github.com:user/new.git` |
| `git fetch` | 拉取远程更新但不自动合并 | `git fetch origin` |
| `git pull` | 拉取并合并远程更新 | `git pull origin main` |
| `git pull --rebase` | 拉取后用 rebase 方式整合 | `git pull --rebase origin main` |
| `git push` | 推送当前分支到远程 | `git push origin main` |
| `git push -u origin <branch>` | 首次推送并建立上游关系 | `git push -u origin feature/login` |
| `git push --force-with-lease` | 更安全地强推分支 | `git push --force-with-lease origin feature/login` |
| `git fetch --prune` | 拉取并清理已删除远程分支引用 | `git fetch --prune` |
| `git remote prune origin` | 清理本地失效的远程跟踪分支 | `git remote prune origin` |

## 七、撤销、回退与恢复

| 命令 | 描述 | 示例 |
|------|------|------|
| `git restore <file>` | 撤销工作区修改 | `git restore README.md` |
| `git restore --staged <file>` | 撤销暂存 | `git restore --staged README.md` |
| `git reset --soft <commit>` | 回退提交，保留暂存区内容 | `git reset --soft HEAD~1` |
| `git reset --mixed <commit>` | 回退提交，保留工作区修改 | `git reset HEAD~1` |
| `git reset --hard <commit>` | 回退提交并丢弃工作区修改 | `git reset --hard HEAD~1` |
| `git revert <commit>` | 生成一个反向提交来撤销历史提交 | `git revert abc1234` |
| `git checkout <commit> -- <file>` | 从旧提交恢复某个文件 | `git checkout HEAD~2 -- src/app.py` |
| `git reflog` | 查找误删分支或误回退前的引用 | `git reflog` |
| `git reset --hard <reflog-id>` | 通过 reflog 恢复现场 | `git reset --hard HEAD@{3}` |

### `reset` 与 `revert` 区别

| 命令 | 是否改写历史 | 适用场景 |
|------|------|------|
| `git reset` | 会 | 本地未共享提交的整理与回退 |
| `git revert` | 不会 | 已推送到共享分支后的安全撤销 |

## 八、Stash 与清理

| 命令 | 描述 | 示例 |
|------|------|------|
| `git stash` | 暂存当前未提交修改 | `git stash` |
| `git stash push -m "<msg>"` | 带说明地暂存 | `git stash push -m "wip: login page"` |
| `git stash list` | 查看 stash 列表 | `git stash list` |
| `git stash show -p stash@{0}` | 查看某个 stash 详细内容 | `git stash show -p stash@{0}` |
| `git stash apply stash@{0}` | 应用 stash 但不删除 | `git stash apply stash@{0}` |
| `git stash pop` | 应用最近 stash 并删除 | `git stash pop` |
| `git stash drop stash@{0}` | 删除指定 stash | `git stash drop stash@{0}` |
| `git stash clear` | 清空所有 stash | `git stash clear` |
| `git clean -n` | 预览将删除哪些未跟踪文件 | `git clean -n` |
| `git clean -fd` | 删除未跟踪文件和目录 | `git clean -fd` |
| `git clean -fdx` | 连 `.env`、构建产物等忽略文件一起删除 | `git clean -fdx` |

## 九、标签管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `git tag` | 查看所有标签 | `git tag` |
| `git tag <tag>` | 创建轻量标签 | `git tag v1.0.0` |
| `git tag -a <tag> -m "<msg>"` | 创建附注标签 | `git tag -a v1.0.0 -m "release v1.0.0"` |
| `git show <tag>` | 查看标签对应信息 | `git show v1.0.0` |
| `git push origin <tag>` | 推送某个标签 | `git push origin v1.0.0` |
| `git push origin --tags` | 推送全部标签 | `git push origin --tags` |
| `git tag -d <tag>` | 删除本地标签 | `git tag -d v1.0.0` |
| `git push origin :refs/tags/<tag>` | 删除远程标签 | `git push origin :refs/tags/v1.0.0` |

## 十、子模块与多仓库依赖

| 命令 | 描述 | 示例 |
|------|------|------|
| `git submodule add <url> <path>` | 添加子模块 | `git submodule add https://github.com/user/lib.git vendor/lib` |
| `git submodule init` | 初始化子模块配置 | `git submodule init` |
| `git submodule update` | 拉取子模块内容到记录版本 | `git submodule update` |
| `git submodule update --init --recursive` | 初始化并递归更新所有子模块 | `git submodule update --init --recursive` |
| `git clone --recurse-submodules` | 克隆仓库时同时拉子模块 | `git clone --recurse-submodules repo-url` |
| `git submodule foreach git pull` | 遍历更新各子模块 | `git submodule foreach git pull` |

## 十一、排查与高级用法

| 命令 | 描述 | 示例 |
|------|------|------|
| `git bisect start` | 启动二分查错 | `git bisect start` |
| `git bisect bad` | 标记当前版本有问题 | `git bisect bad` |
| `git bisect good <commit>` | 标记一个正常提交 | `git bisect good abc1234` |
| `git bisect reset` | 结束 bisect | `git bisect reset` |
| `git worktree add ../repo-fix hotfix/api` | 为同仓库创建额外工作树 | `git worktree add ../repo-fix hotfix/api` |
| `git worktree list` | 查看所有工作树 | `git worktree list` |
| `git worktree remove ../repo-fix` | 删除工作树 | `git worktree remove ../repo-fix` |
| `git archive` | 导出某次提交的代码快照 | `git archive --format=zip HEAD -o release.zip` |

## 十二、常用实战组合

```bash
# 1. 初始化仓库并提交第一版
git init
git add .
git commit -m "feat: initial commit"

# 2. 从 main 拉新分支开发
git switch main
git pull --rebase origin main
git switch -c feature/login

# 3. 查看改动并提交
git status -sb
git diff
git add .
git commit -m "feat: add login page"

# 4. 同步主干最新代码到当前分支
git fetch origin
git rebase origin/main

# 5. 推送当前分支并建立上游
git push -u origin feature/login

# 6. 提交后发现要补一个文件
git add missing-file.txt
git commit --amend --no-edit

# 7. 临时切任务，把当前改动收起来
git stash push -m "wip: payment page"
git switch hotfix/api-timeout

# 8. 找回误删的提交
git reflog
git reset --hard HEAD@{2}

# 9. 安全撤销线上已有提交
git revert <commit>

# 10. 清空未跟踪文件前先预览
git clean -n
git clean -fd
```

## 十三、速记

- 看状态：`git status -sb`
- 看差异：`git diff`、`git diff --staged`
- 提交：`git add .` + `git commit -m "..."`
- 切分支：`git switch -c feature/x`
- 同步远程：`git fetch`、`git pull --rebase`
- 推送分支：`git push -u origin 当前分支`
- 找回现场：`git reflog`
- 安全撤销共享历史：`git revert`
- 高风险命令：`git reset --hard`、`git clean -fdx`、`git push --force`
