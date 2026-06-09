# Claude Code 命令大全

## 内置斜杠命令

| 命令 | 描述 |
|------|------|
| `/help` | 显示帮助信息和可用命令列表 |
| `/clear` | 清除当前对话上下文，重新开始 |
| `/compact` | 压缩对话历史，减少 token 使用量，保留关键上下文 |
| `/config` | 查看或修改 Claude Code 配置 |
| `/cost` | 显示当前会话的 token 使用量和费用统计 |
| `/doctor` | 诊断 Claude Code 环境问题（权限、配置等） |
| `/init` | 在当前项目初始化 `CLAUDE.md` 文件 |
| `/login` | 登录 Anthropic 账户 |
| `/logout` | 退出当前账户 |
| `/memory` | 查看和编辑 `CLAUDE.md` 记忆文件 |
| `/model` | 查看或切换当前使用的模型 |
| `/permissions` | 管理工具权限（允许/拒绝） |
| `/pr-comments` | 查看当前 PR 的评论 |
| `/review` | 对当前更改进行代码审查 |
| `/status` | 显示当前 git 状态和会话信息 |
| `/terminal-setup` | 配置终端集成（Shift+Enter 换行等） |
| `/vim` | 切换 Vim 编辑模式 |

## CLI 启动参数

| 参数 | 描述 |
|------|------|
| `claude` | 启动交互式 REPL 会话 |
| `claude "prompt"` | 执行单次提问，输出后退出 |
| `claude -c` / `--continue` | 继续上一次对话 |
| `claude -r` / `--resume` | 选择并恢复历史会话 |
| `claude -p "prompt"` | 非交互模式（管道模式），适合脚本调用 |
| `claude --model <model>` | 指定使用的模型 |
| `claude --allowedTools <tools>` | 指定允许的工具列表 |
| `claude --disallowedTools <tools>` | 指定禁用的工具列表 |
| `claude --max-turns <n>` | 限制最大对话轮数（非交互模式） |
| `claude --system-prompt <prompt>` | 自定义系统提示词（仅 `-p` 模式） |
| `claude --output-format <format>` | 输出格式：`text`、`json`、`stream-json` |
| `claude --verbose` | 开启详细日志输出 |
| `claude --dangerously-skip-permissions` | 跳过所有权限确认（⚠️ 危险） |
| `claude config` | 管理配置项 |
| `claude update` | 更新 Claude Code 到最新版本 |
| `claude mcp` | 管理 MCP 服务器 |

## MCP 管理子命令

| 命令 | 描述 |
|------|------|
| `claude mcp list` | 列出所有已配置的 MCP 服务器 |
| `claude mcp add <name> <command> [args...]` | 添加一个 stdio 类型的 MCP 服务器 |
| `claude mcp add --transport sse <name> <url>` | 添加一个 SSE 类型的 MCP 服务器 |
| `claude mcp remove <name>` | 移除指定 MCP 服务器 |
| `claude mcp serve` | 将 Claude Code 自身作为 MCP 服务器运行 |

## Config 管理子命令

| 命令 | 描述 |
|------|------|
| `claude config list` | 列出所有配置项 |
| `claude config get <key>` | 获取某个配置项的值 |
| `claude config set <key> <value>` | 设置配置项 |
| `claude config remove <key>` | 删除配置项 |

## 交互模式快捷键

| 快捷键 | 描述 |
|--------|------|
| `Enter` | 发送消息 |
| `Shift+Enter` | 换行（需终端支持） |
| `Escape` | 取消当前正在执行的操作 |
| `Ctrl+C` | 中断当前操作或退出 |
| `Tab` | 自动补全文件路径 |
| `@file` | 引用文件，将其内容加入上下文 |
| `!command` | 直接执行 shell 命令 |

## 权限级别说明

| 级别 | 描述 |
|------|------|
| **Allow** | 永久允许该工具执行 |
| **Deny** | 永久拒绝该工具执行 |
| **Allow for session** | 仅本次会话允许 |
| **Allow once** | 仅允许本次调用 |

## 核心内置工具

| 工具 | 描述 |
|------|------|
| **Read** | 读取文件内容（支持图片、PDF、Notebook） |
| **Write** | 写入/创建文件 |
| **Edit** | 精确编辑文件（字符串替换） |
| **Bash** | 执行 Shell 命令 |
| **Glob** | 按模式搜索文件名 |
| **Grep** | 按正则搜索文件内容 |
| **Agent** | 启动子代理执行复杂任务 |
| **WebFetch** | 抓取网页内容 |
| **WebSearch** | 搜索互联网 |
| **TodoWrite** | 管理任务清单 |
| **NotebookEdit** | 编辑 Jupyter Notebook |
| **LSP** | 调用语言服务器协议功能 |
