---
title: Codex 命令大全
aliases:
  - codex命令大全
  - Codex CLI 命令大全
tags:
  - 命令大全
  - Codex
  - AI工具
updated: 2026-04-09
version: codex-cli 0.118.0
---

# Codex 命令大全

> [!info]
> 本文基于当前机器实测 `codex --help` 与各子命令 `--help` 输出整理，版本为 `codex-cli 0.118.0`。
> 当前本地帮助主要暴露的是 CLI 命令，不像 [[Claude Code 命令大全]] 那样单独列出一套内置斜杠命令，因此这里以终端命令为主。

## 常用启动方式

| 命令 | 描述 |
|------|------|
| `codex` | 启动交互式 Codex CLI |
| `codex "帮我修这个 bug"` | 启动交互式会话，并把这句 prompt 作为初始任务 |
| `codex exec "帮我分析当前仓库"` | 非交互执行一次任务，适合脚本或自动化 |
| `codex review --uncommitted` | 审查当前工作区里未提交的改动 |
| `codex resume --last` | 继续最近一次交互式会话 |
| `codex fork --last` | 基于最近一次会话分叉出一个新会话 |
| `codex login` | 登录 Codex |
| `codex logout` | 退出当前登录状态 |

## 一级命令

| 命令 | 描述 |
|------|------|
| `codex` | 默认启动交互式 CLI；如果后面直接跟 prompt，则以该 prompt 开始会话 |
| `codex exec` / `codex e` | 非交互执行任务 |
| `codex review` | 非交互执行代码审查 |
| `codex login` | 登录管理 |
| `codex logout` | 清除本地登录凭据 |
| `codex mcp` | 管理外部 MCP 服务器 |
| `codex mcp-server` | 将 Codex 自身作为 MCP Server 运行（stdio） |
| `codex app-server` | 运行或生成与 app server 相关的实验性工具 |
| `codex completion` | 生成 shell 自动补全脚本 |
| `codex sandbox` | 在 Codex 提供的沙箱中执行命令 |
| `codex debug` | 调试工具入口 |
| `codex apply` / `codex a` | 将 Codex 任务生成的 diff 应用到本地工作区 |
| `codex resume` | 恢复历史交互式会话 |
| `codex fork` | 从已有会话分叉出新会话 |
| `codex cloud` | 浏览或应用 Codex Cloud 任务（实验性） |
| `codex features` | 查看或修改 feature flags |
| `codex help` | 查看帮助 |

## `exec` 非交互执行

| 命令 | 描述 |
|------|------|
| `codex exec [PROMPT]` | 非交互执行一次任务；如果 prompt 省略或传 `-`，则从 stdin 读取 |
| `codex exec resume [SESSION_ID] [PROMPT]` | 恢复历史 session 后继续在非交互模式执行 |
| `codex exec review [PROMPT]` | 在非交互模式下执行代码审查 |

常用参数：

| 参数 | 描述 |
|------|------|
| `--skip-git-repo-check` | 允许在非 Git 仓库中运行 |
| `--ephemeral` | 不把 session 文件持久化到磁盘 |
| `--output-schema <FILE>` | 用 JSON Schema 约束最终输出格式 |
| `--json` | 以 JSONL 事件流输出 |
| `-o, --output-last-message <FILE>` | 把最后一条消息写入指定文件 |

## `review` 代码审查

| 命令 / 参数 | 描述 |
|-------------|------|
| `codex review [PROMPT]` | 对当前仓库执行一次非交互代码审查 |
| `--uncommitted` | 审查未提交的改动，包括 staged / unstaged / untracked |
| `--base <BRANCH>` | 与指定分支对比后进行审查 |
| `--commit <SHA>` | 仅审查某次提交引入的改动 |
| `--title <TITLE>` | 给审查结果附带标题 |

## `login` / `logout` 登录相关

| 命令 | 描述 |
|------|------|
| `codex login` | 登录入口 |
| `codex login status` | 查看当前登录状态 |
| `codex login --with-api-key` | 从 stdin 读取 API Key 登录 |
| `codex login --device-auth` | 使用设备认证方式登录 |
| `codex logout` | 删除本地保存的认证凭据 |

## `mcp` 管理外部 MCP 服务器

| 命令 | 描述 |
|------|------|
| `codex mcp list` | 列出所有已配置 MCP 服务器 |
| `codex mcp get <NAME>` | 查看指定 MCP 服务器配置 |
| `codex mcp add <NAME> --url <URL>` | 添加一个基于 streamable HTTP 的 MCP 服务 |
| `codex mcp add <NAME> -- <COMMAND>...` | 添加一个通过本地命令启动的 stdio MCP 服务 |
| `codex mcp remove <NAME>` | 删除指定 MCP 配置 |
| `codex mcp login <NAME>` | 对某个 MCP 服务执行 OAuth 登录 |
| `codex mcp logout <NAME>` | 取消某个 MCP 服务的认证 |

`mcp add` 常用参数：

| 参数 | 描述 |
|------|------|
| `--env <KEY=VALUE>` | 为 stdio MCP 服务注入环境变量 |
| `--url <URL>` | 指定 HTTP MCP 服务地址 |
| `--bearer-token-env-var <ENV_VAR>` | 从环境变量读取 Bearer Token，用于 HTTP MCP 服务 |
| `--json` | `mcp list` / `mcp get` 输出 JSON |
| `--scopes <SCOPE,SCOPE>` | `mcp login` 时请求的 OAuth scope |

## `cloud` Codex Cloud（实验性）

| 命令 | 描述 |
|------|------|
| `codex cloud exec --env <ENV_ID> [QUERY]` | 提交一个新的 Cloud 任务，不启动 TUI |
| `codex cloud status <TASK_ID>` | 查看某个 Cloud 任务状态 |
| `codex cloud list` | 列出 Cloud 任务 |
| `codex cloud apply <TASK_ID>` | 将 Cloud 任务生成的 diff 应用到本地 |
| `codex cloud diff <TASK_ID>` | 查看 Cloud 任务的统一 diff |

常用参数：

| 参数 | 描述 |
|------|------|
| `--env <ENV_ID>` | 指定 Cloud 环境 ID |
| `--attempts <ATTEMPTS>` | 提交任务时设置 best-of-N 尝试次数 |
| `--branch <BRANCH>` | 指定 Cloud 任务运行的 Git 分支 |
| `--limit <N>` | `cloud list` 返回任务数量上限 |
| `--cursor <CURSOR>` | `cloud list` 分页游标 |
| `--json` | `cloud list` 以 JSON 输出 |
| `--attempt <N>` | `cloud apply` / `cloud diff` 指定第几次尝试结果 |

## `features` Feature Flag 管理

| 命令 | 描述 |
|------|------|
| `codex features list` | 列出已知 feature 及当前生效状态 |
| `codex features enable <FEATURE>` | 在 `config.toml` 中启用某个 feature |
| `codex features disable <FEATURE>` | 在 `config.toml` 中禁用某个 feature |

## `sandbox` / `app-server` / `debug`

| 命令 | 描述 |
|------|------|
| `codex sandbox` | 沙箱执行入口 |
| `codex sandbox windows [COMMAND]...` | 在 Windows restricted token 沙箱下运行命令 |
| `codex mcp-server` | 把 Codex 作为 MCP Server 启动 |
| `codex app-server` | app server 相关实验命令入口 |
| `codex app-server generate-ts --out <DIR>` | 生成 app server 协议对应的 TypeScript 绑定 |
| `codex app-server generate-json-schema --out <DIR>` | 生成 app server 协议的 JSON Schema |
| `codex debug app-server` | app server 调试工具入口 |

补充说明：

- `codex sandbox` 还列出了 `macos`、`linux` 两个平台子命令，用于对应系统的沙箱执行。
- `codex app-server`、`codex cloud` 明确标记为实验性功能。

## 全局常用参数

这些参数在很多一级命令上都能使用：

| 参数 | 描述 |
|------|------|
| `-c, --config <key=value>` | 覆盖 `~/.codex/config.toml` 中的配置项 |
| `--enable <FEATURE>` | 临时启用某个 feature |
| `--disable <FEATURE>` | 临时禁用某个 feature |
| `-m, --model <MODEL>` | 指定模型 |
| `--oss` | 使用本地开源模型提供方 |
| `--local-provider <OSS_PROVIDER>` | 指定本地模型提供方，如 `lmstudio` 或 `ollama` |
| `-p, --profile <CONFIG_PROFILE>` | 使用某个配置 profile |
| `-s, --sandbox <SANDBOX_MODE>` | 指定沙箱模式：`read-only`、`workspace-write`、`danger-full-access` |
| `-a, --ask-for-approval <APPROVAL_POLICY>` | 指定审批策略：`untrusted`、`on-request`、`never` 等 |
| `--full-auto` | 低摩擦自动执行的快捷组合参数 |
| `--dangerously-bypass-approvals-and-sandbox` | 跳过审批与沙箱，直接执行，风险极高 |
| `-C, --cd <DIR>` | 指定工作目录 |
| `--add-dir <DIR>` | 额外添加可写目录 |
| `-i, --image <FILE>` | 给初始 prompt 附加图片 |
| `--search` | 启用实时网页搜索能力 |
| `--remote <ADDR>` | 连接远程 app server websocket |
| `--remote-auth-token-env <ENV_VAR>` | 远程 app server Bearer Token 的环境变量名 |
| `--no-alt-screen` | 禁用 alternate screen，保留终端滚动历史 |
| `-h, --help` | 查看帮助 |
| `-V, --version` | 查看版本 |

## 常用示例

```bash
# 启动交互式会话
codex

# 进入当前项目并直接给一个任务
codex -C /path/to/repo "帮我解释这个仓库的结构"

# 非交互执行并把最后回复写入文件
codex exec "总结当前目录的项目结构" -o result.txt

# 审查当前未提交代码
codex review --uncommitted

# 恢复最近会话
codex resume --last

# 添加一个 HTTP 类型的 MCP 服务
codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp

# 在 Windows 沙箱里执行命令
codex sandbox windows powershell -NoLogo -Command Get-ChildItem
```

## 速记

- 想进入交互模式：`codex`
- 想一次性执行任务：`codex exec`
- 想做代码审查：`codex review`
- 想接入外部工具：`codex mcp`
- 想恢复历史上下文：`codex resume`
- 想分叉一条新思路：`codex fork`
