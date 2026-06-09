**Swish** 是一种激活函数，由 Google 的研究团队在 2017 年提出。它结合了 **ReLU** 和 **Sigmoid** 的特性，表现出了优异的性能，尤其是在深度学习模型中。Swish 的计算公式及其特点如下：

###### Swish 的公式

Swish 的数学公式为：

其中：

-  是输入值。
-  是 **Sigmoid** 函数，定义为：

-  是一个可学习的参数（或固定值，通常默认为 1）。

当  时，Swish 的公式简化为：

###### 直观理解

Swish 可以理解为对输入值  进行加权，权重由 Sigmoid 函数决定：

- 当  为正时， 接近 1，因此 。
- 当  为负时， 接近 0，因此  逐渐趋近于 0。
- Swish 在  附近是平滑的，且具有非单调性（即函数值在某些区间内会先减小后增大）。

###### 与 ReLU 的对比

1. **平滑性**：

- ReLU 在  处不可导，而 Swish 在整个定义域内都是平滑的。

2. **负值处理**：

- ReLU 将负值直接置为 0，而 Swish 对负值进行平滑处理，保留部分信息。

3. **非单调性**：

- Swish 在某些区间内具有非单调性，这使其能够更好地捕捉复杂特征。

###### 代码实现（PyTorch）

以下是 Swish 的 PyTorch 实现：

```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class Swish(nn.Module):
    def __init__(self, beta=1.0):
        """
        Swish 初始化
        :param beta: 可学习参数（默认为 1.0）
        """
        super(Swish, self).__init__()
        self.beta = beta

    def forward(self, x):
        """
        Swish 前向传播
        :param x: 输入张量
        :return: 输出张量
        """
        return x * torch.sigmoid(self.beta * x)

# 示例：使用 Swish
swish = Swish(beta=1.0)
x = torch.tensor([-2.0, -1.0, 0.0, 1.0, 2.0])
output = swish(x)
print(output)  # 输出张量
```

###### 优点

1. **性能优异**：

- 在多个深度学习任务中，Swish 的表现优于 ReLU 和其他激活函数。

2. **平滑性**：

- Swish 的平滑性有助于优化算法的收敛。

3. **适应性**：

- 通过调整  参数，Swish 可以适应不同的任务和模型。

###### 应用场景

Swish 广泛应用于深度学习模型，尤其是在以下场景中：

1. **图像分类**：

- 在卷积神经网络（CNN）中，Swish 可以替代 ReLU 作为激活函数。

2. **自然语言处理**：

- 在 Transformer 模型中，Swish 可以用于 FFN（Feed-Forward Network）层。

3. **强化学习**：

- Swish 的非单调性使其适合处理复杂的强化学习任务。

###### 总结

Swish 是一种结合了 ReLU 和 Sigmoid 特性的激活函数，其公式为：

Swish 具有平滑性、非单调性和优异的性能，在多个深度学习任务中表现良好。通过调整  参数，Swish 可以适应不同的任务和模型。
