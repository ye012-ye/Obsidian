Elasticsearch 中的 **Analyzer** 是一种文本处理组件，用于将原始字符串拆解为索引与查询所需的词项（tokens）。它执行在两种关键时机：**索引阶段**和**查询阶段**，为创建倒排索引与处理用户输入做准备。

M

### 1. 分析管线结构

Analyzer 由三个主要环节组成：**字符过滤器**（Char Filters，可选）、**分词器**（Tokenizer，必须）与**词项过滤器**（Token Filters，可选）。

- **字符过滤器**清理或转换输入字符串，如`html_strip`移除HTML标签。
- **分词器**将文本拆分成单个词项，例如标准分词器根据空格和标点分词。
- **词项过滤器**进一步处理分词结果，如统一小写、去除停用词、词干提取等。

### 2. 索引与查询流程

- 在索引时，Analyzer 将文档字段分解成词项并写入倒排索引。
- 在用户查询时，同样的 Analyzer 将查询语句拆解成相同的词项，以便于匹配索引内容。

这样，查询过程与索引过程对称，保证检索的一致性和准确性。

S

### 3. 内置与自定义 Analyzer

Elasticsearch 提供多种内置 Analyzer，如 `standard`、`simple`、`whitespace`、`stop`、语言分析器（如 `english`）、`keyword`、`pattern` 等。

当需要满足特定需求时，也可以自定义 Analyzer，通过配置字符过滤、Tokenizer 以及 Token Filters 的组合生成新的处理管道。

​

Analyzer 直接影响文本索引的粒度与形式，因此决定了搜索命中率和相关性。例如，正确使用 **词干过滤**可以将 “running” 标准化为 “run”，提升短语和变形词的检索精度。B
