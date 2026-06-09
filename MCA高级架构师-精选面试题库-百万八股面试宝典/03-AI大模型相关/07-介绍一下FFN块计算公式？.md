在 Transformer 模型中，**Feed-Forward Network（FFN）** 是每一层的重要组成部分，用于对输入特征进行非线性变换。FFN 通常由两个全连接层（线性层）和一个激活函数组成。以下是 FFN 块的计算公式及其详细说明。

###### FFN 块的公式

FFN 的计算公式可以表示为：

其中：

-  是输入特征，形状为 ，其中  是模型的隐藏层维度。
-  和  是第一个全连接层的权重和偏置，形状分别为  和 ，其中  是 FFN 的中间维度（通常 ）。
-  和  是第二个全连接层的权重和偏置，形状分别为  和 。
-  是激活函数，用于引入非线性。

###### 计算步骤

1. **第一个全连接层**：

- 将输入  通过第一个全连接层进行线性变换：

```plain
 $$
 h = W_1 \cdot x + b_1
 $$
```

- 输出的形状为 。

2. **激活函数**：

- 对  应用 ReLU 激活函数：

```plain
 $$
 h' = \text{ReLU}(h)
 $$
```

- ReLU 的作用是引入非线性，同时保留正值特征。

3. **第二个全连接层**：

- 将  通过第二个全连接层进行线性变换：

```plain
 $$
 y = W_2 \cdot h' + b_2
 $$
```

- 输出的形状为 ，与输入  的形状一致。

###### 代码实现（PyTorch）

以下是一个简单的 FFN 块的 PyTorch 实现：

```python
import torch
import torch.nn as nn

class FeedForwardNetwork(nn.Module):
    def __init__(self, d_model, d_ff):
        """
        FFN 初始化
        :param d_model: 隐藏层维度
        :param d_ff: FFN 的中间维度
        """
        super(FeedForwardNetwork, self).__init__()
        self.fc1 = nn.Linear(d_model, d_ff)  # 第一个全连接层
        self.fc2 = nn.Linear(d_ff, d_model)  # 第二个全连接层
        self.relu = nn.ReLU()  # 激活函数

    def forward(self, x):
        """
        FFN 前向传播
        :param x: 输入张量，形状为 (batch_size, seq_len, d_model)
        :return: 输出张量，形状为 (batch_size, seq_len, d_model)
        """
        h = self.fc1(x)  # 第一个全连接层
        h = self.relu(h)  # 激活函数
        y = self.fc2(h)  # 第二个全连接层
        return y

# 示例：使用 FFN
d_model = 512
d_ff = 2048
ffn = FeedForwardNetwork(d_model, d_ff)

# 输入数据
batch_size = 10
seq_len = 20
x = torch.randn(batch_size, seq_len, d_model)

# 前向传播
output = ffn(x)
print(output.shape)  # 输出形状为 (10, 20, 512)
```

###### 变体与改进

1. **Gated Linear Units (GLU)**：

- 使用 GLU 代替 ReLU，公式为：

```plain
 $$
 \text{GLU}(x) = (W_1 \cdot x + b_1) \otimes \sigma(W_2 \cdot x + b_2)
 $$

 其中 $\sigma$ 是 sigmoid 函数，$\otimes$ 是逐元素乘法。
```

2. **GELU 激活函数**：

- 使用 GELU（Gaussian Error Linear Unit）代替 ReLU，公式为：

```plain
 $$
 \text{GELU}(x) = x \cdot \Phi(x)
 $$

 其中 $\Phi(x)$ 是标准正态分布的累积分布函数。
```

3. **参数共享**：

- 在某些模型中，FFN 的参数在不同层之间共享，以减少模型参数量。

###### 总结

FFN 块是 Transformer 模型中的核心组件之一，通过两个全连接层和一个激活函数对输入特征进行非线性变换。其计算公式为：

FFN 的设计简单而有效，能够显著提升模型的表达能力。通过引入不同的激活函数或结构变体，可以进一步优化 FFN 的性能。
