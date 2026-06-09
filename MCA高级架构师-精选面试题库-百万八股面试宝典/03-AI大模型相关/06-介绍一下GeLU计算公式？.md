**GELU（Gaussian Error Linear Unit）** 是一种激活函数，广泛用于现代深度学习模型（如 Transformer、BERT、GPT 等）。GELU 通过结合输入值的概率分布（高斯分布）来引入非线性，能够更好地捕捉数据的复杂特征。以下是 GELU 的计算公式及其详细说明。

###### GELU 的公式

GELU 的数学公式为：

其中：

- 是输入值。
- 是标准正态分布的累积分布函数（CDF），即：

-  是误差函数（Error Function），定义为：

```plain
$$
\text{erf}(x) = \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} dt
$$
```

###### 近似公式

由于  的计算涉及积分，实际应用中通常使用以下近似公式：

这个近似公式计算效率高，且精度足够。

###### 直观理解

GELU 可以理解为对输入值 进行加权，权重是  在标准正态分布下的累积概率 ：

- 当较大时，，因此 。
- 当 较小时，，因此。
- 当  为负值时，会逐渐趋近于 0，但比 ReLU 更加平滑。

###### 代码实现（PyTorch）

以下是 GELU 的 PyTorch 实现，包括精确计算和近似计算：

```python
import torch
import torch.nn as nn
import math

class GELU(nn.Module):
    def __init__(self, approximate=False):
        """
        GELU 初始化
        :param approximate: 是否使用近似公式
        """
        super(GELU, self).__init__()
        self.approximate = approximate

    def forward(self, x):
        """
        GELU 前向传播
        :param x: 输入张量
        :return: 输出张量
        """
        if self.approximate:
            # 近似公式
            return 0.5 * x * (1 + torch.tanh(math.sqrt(2 / math.pi) * (x + 0.044715 * torch.pow(x, 3))))
        else:
            # 精确公式
            return x * 0.5 * (1.0 + torch.erf(x / math.sqrt(2.0)))

# 示例：使用 GELU
gelu = GELU(approximate=True)
x = torch.tensor([-2.0, -1.0, 0.0, 1.0, 2.0])
output = gelu(x)
print(output)  # 输出张量
```

###### 与 ReLU 的对比

1. **平滑性**：

- ReLU 在  处不可导，而 GELU 在整个定义域内都是平滑的。

2. **负值处理**：

- ReLU 将负值直接置为 0，而 GELU 对负值进行平滑处理，保留部分信息。

3. **表达能力**：

- GELU 能够更好地捕捉数据的复杂特征，适合深层网络。

###### 应用场景

GELU 广泛应用于现代深度学习模型，尤其是在 Transformer 及其变体中：

- **BERT**：在每一层的 FFN 中使用 GELU 作为激活函数。
- **GPT 系列**：在每一层的 FFN 中使用 GELU 作为激活函数。
- **Vision Transformers**：在图像分类任务中使用 GELU 作为激活函数。

###### 总结

GELU 是一种基于高斯分布的激活函数，其公式为：

通过结合输入值的概率分布，GELU 能够更好地捕捉数据的复杂特征，同时具有平滑性和高效性。在实际应用中，通常使用近似公式进行计算。GELU 在 Transformer 及其变体中得到了广泛应用，显著提升了模型的性能。
