
## Hooks 和 Interceptors 能做什么？

- 监控：使用日志、分析和调试跟踪 Agent 行为；
    
- 修改：转换提示、工具选择和输出格式；
    
- 控制：添加重试、回退和提前终止逻辑；
    
- 强制执行：应用速率限制、护栏和 PII 检测。
    

## 内置实现

Spring AI Alibaba 为常见用例提供了预构建的 Hooks 和 Interceptors 实现：

### 消息压缩（Summarization）

当接近 token 限制时自动压缩对话历史。

**适用场景**：

- 超出上下文窗口的长期对话；
- 具有大量历史记录的多轮对话；
- 需要保留完整对话上下文的应用程序。

```
import com.alibaba.cloud.ai.graph.agent.hook.summarization.SummarizationHook;

// 创建消息压缩 Hook
SummarizationHook summarizationHook = SummarizationHook.builder()
.model(chatModel)
.maxTokensBeforeSummary(4000)
.messagesToKeep(20)
.build();

// 使用
ReactAgent agent = ReactAgent.builder()
.name("my_agent")
.model(chatModel)
.hooks(summarizationHook)
.build();
```

**配置选项**：

- `model`: 用于生成摘要的 ChatModel；
- `maxTokensBeforeSummary`: 触发摘要之前的最大 token 数；
- `messagesToKeep`: 摘要后保留的最新消息数。


### Human-in-the-Loop（人机协同）

暂停 Agent 执行以获得人工批准、编辑或拒绝工具调用。

**适用场景**：

- 需要人工批准的高风险操作（数据库写入、金融交易）；
- 人工监督是强制性的合规工作流程；
- 长期对话，使用人工反馈引导 Agent。


```
import com.alibaba.cloud.ai.graph.agent.hook.hip.HumanInTheLoopHook;
import com.alibaba.cloud.ai.graph.agent.hook.hip.ToolConfig;

// 创建 Human-in-the-Loop Hook
HumanInTheLoopHook humanReviewHook = HumanInTheLoopHook.builder()
.approvalOn("sendEmailTool", ToolConfig.builder().description("Please confirm sending the email.").build())
.approvalOn("deleteDataTool")
.build();

ReactAgent agent = ReactAgent.builder()
.name("supervised_agent")
.model(chatModel)
.tools(sendEmailTool, deleteDataTool)
.hooks(humanReviewHook)
.saver(new RedisSaver())
.build();
```

**重要提示**：Human-in-the-loop Hook 需要 checkpointer 来维护跨中断的状态。示例中我们演示用了 `RedisSaver`。


### 模型调用限制（Model Call Limit）

限制模型调用次数以防止无限循环或过度成本。

**适用场景**：

- 防止失控的 Agent 进行太多 API 调用；
- 在生产部署中强制执行成本控制；
- 在特定调用预算内测试 Agent 行为。

ModelCallLimitHook 模型调用限制示例[查看完整代码](https://github.com/alibaba/spring-ai-alibaba/tree/main/examples/documentation/src/main/java/com/alibaba/cloud/ai/examples/documentation/framework/tutorials/HooksExample.java "查看完整源代码")

```
ReactAgent agent = ReactAgent.builder()
.name("my_agent")
.model(chatModel)
.hooks(ModelCallLimitHook.builder().runLimit(5).build()) // 限制模型调用次数为5次
.saver(new MemorySaver())
.build();
```


### PII 检测（Personally Identifiable Information）

检测和处理对话中的个人身份信息。

**适用场景**：

- 具有合规要求的医疗保健和金融应用；
- 需要清理日志的客户服务 Agent；
- 任何处理敏感用户数据的应用程序。

PIIDetectionHook PII 检测示例[查看完整代码](https://github.com/alibaba/spring-ai-alibaba/tree/main/examples/documentation/src/main/java/com/alibaba/cloud/ai/examples/documentation/framework/tutorials/HooksExample.java "查看完整源代码")

```
import com.alibaba.cloud.ai.graph.agent.hook.pii.PIIDetectionHook;
import com.alibaba.cloud.ai.graph.agent.hook.pii.PIIType;
import com.alibaba.cloud.ai.graph.agent.hook.pii.RedactionStrategy;

PIIDetectionHook pii = PIIDetectionHook.builder()
.piiType(PIIType.EMAIL)
.strategy(RedactionStrategy.REDACT)
.applyToInput(true)
.build();

// 使用
ReactAgent agent = ReactAgent.builder()
.name("secure_agent")
.model(chatModel)
.hooks(pii)
.build();
```


### 工具重试（Tool Retry）

自动重试失败的工具调用，具有可配置的指数退避。

**适用场景**：

- 处理外部 API 调用中的瞬态故障；
- 提高依赖网络的工具的可靠性；
- 构建优雅处理临时错误的弹性 Agent。

ToolRetryInterceptor 工具重试示例[查看完整代码](https://github.com/alibaba/spring-ai-alibaba/tree/main/examples/documentation/src/main/java/com/alibaba/cloud/ai/examples/documentation/framework/tutorials/HooksExample.java "查看完整源代码")

```
import com.alibaba.cloud.ai.graph.agent.interceptor.toolretry.ToolRetryInterceptor;

// 使用
ReactAgent agent = ReactAgent.builder()
.name("resilient_agent")
.model(chatModel)
.tools(searchTool, databaseTool)
.interceptors(ToolRetryInterceptor.builder()
.maxRetries(2)
.onFailure(ToolRetryInterceptor.OnFailureBehavior.RETURN_MESSAGE)
.build())
.build();
```



### Planning（规划）

在执行工具之前强制执行一个规划步骤，以概述 Agent 将要采取的步骤。

**适用场景**：

- 需要执行复杂、多步骤任务的 Agent；
- 通过在执行前显示 Agent 的计划来提高透明度；
- 通过检查建议的计划来调试错误。

TodoListInterceptor 规划示例[查看完整代码](https://github.com/alibaba/spring-ai-alibaba/tree/main/examples/documentation/src/main/java/com/alibaba/cloud/ai/examples/documentation/framework/tutorials/HooksExample.java "查看完整源代码")

```
import com.alibaba.cloud.ai.graph.agent.interceptor.todolist.TodoListInterceptor;

// 使用
ReactAgent agent = ReactAgent.builder()
.name("planning_agent")
.model(chatModel)
.tools(myTool)
.interceptors(TodoListInterceptor.builder().build())
.build();
```

### Context Editing（上下文编辑）

在将上下文发送给 LLM 之前对其进行修改，以注入、删除或修改信息。

**适用场景**：

- 向 LLM 提供额外的上下文或指令；
- 从对话历史中删除不相关或冗余的信息；
- 动态修改上下文以引导 Agent 的行为。

ContextEditingInterceptor 上下文编辑示例[查看完整代码](https://github.com/alibaba/spring-ai-alibaba/tree/main/examples/documentation/src/main/java/com/alibaba/cloud/ai/examples/documentation/framework/tutorials/HooksExample.java "查看完整源代码")

```
import com.alibaba.cloud.ai.graph.agent.interceptor.contextediting.ContextEditingInterceptor;

// 使用
ReactAgent agent = ReactAgent.builder()
.name("context_aware_agent")
.model(chatModel)
.interceptors(ContextEditingInterceptor.builder().trigger(120000).clearAtLeast(60000).build())
.build();
```


## 自定义 Hooks 和 Interceptors

通过实现在 Agent 执行流程中特定点运行的钩子来构建自定义功能。

你可以通过以下方式创建自定义功能：

1. **MessagesModelHook** - 在模型调用前后执行，专注于消息操作（推荐）；
2. **ModelHook** - 在模型调用前后执行，可访问完整状态；
3. **AgentHook** - 在 Agent 开始和结束时执行；
4. **ModelInterceptor** - 拦截和修改模型请求/响应；
5. **ToolInterceptor** - 拦截和修改工具调用。

### MessagesModelHook vs ModelHook：如何选择？

`MessagesModelHook` 和 `ModelHook` 都可以在模型调用前后执行自定义逻辑，但它们有不同的设计目标和适用场景。

#### 核心区别

|特性|MessagesModelHook|ModelHook|
|---|---|---|
|**易用性**|⭐⭐⭐⭐⭐ 更简单，直接操作消息列表|⭐⭐⭐ 需要理解 `OverAllState`|
|**灵活性**|⭐⭐⭐ 专注于消息操作|⭐⭐⭐⭐⭐ 可访问和修改完整状态|
|**推荐场景**|消息修剪、过滤、添加系统提示|需要访问全局状态、自定义状态管理|
|**API 复杂度**|简单：`AgentCommand` 返回消息列表|复杂：返回 `Map<String, Object>` 更新状态|

#### 使用建议

**选择 MessagesModelHook，如果你需要：**

- ✅ 简单的消息操作（修剪、过滤、转换）；
- ✅ 添加或修改系统提示；
- ✅ 消息压缩和摘要；
- ✅ 快速实现消息相关的 Hook。

**选择 ModelHook，如果你需要：**

- ✅ 访问和修改 `OverAllState` 中的其他数据；
- ✅ 在状态中存储自定义信息（如计数器、缓存等）；
- ✅ 基于全局状态做复杂决策；
- ✅ 需要查看 Agent 执行过程中的完整上下文。