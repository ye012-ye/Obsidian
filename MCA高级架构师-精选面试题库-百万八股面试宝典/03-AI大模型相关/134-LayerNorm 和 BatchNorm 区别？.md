在深度学习中，归一化技术用于稳定训练和加速收敛。**BatchNorm** 是在 mini‑batch 内对每个特征维度进行归一化，**LayerNorm** 则是在每个样本的所有特征维度上进行归一化，因此二者在适用场景上有明显差异。M

BatchNorm 最初提出是为了减少内部协变量偏移（internal covariate shift），通过对 batch 中每个特征维度进行归一化，使网络能够使用更高的学习率并更快收敛。这种方法在计算机视觉（如 CNN）任务中应用广泛，通常效果显著。S

相比之下，LayerNorm 对单个样本所有隐藏维度进行归一化，与 batch 大小无关，训练和推理过程一致。这使其特别适合处理变长序列的任务，如 NLP 模型、Transformer 结构和 RNN。其稳定性优于 BatchNorm，尤其在小 batch 或动态输入长度时表现良好。

Transformer 和大多数语言模型几乎都采用 LayerNorm，而非 BatchNorm。这是因为 NLP 数据在 batch 维度上的统计波动较大，BatchNorm 在这种情况下会导致训练不稳定甚至性能下降。

B

### 口语化回答示例

在一个 Transformer 基础的文本分类项目中，由于输入文本长度不固定、batch size 较小，使用 BatchNorm 会导致训练抖动，甚至出现验证性能下降的问题。后来我们改用 LayerNorm 替代引入，在每个 attention 和 Feed-Forward 层后统一归一化隐藏向量。这不仅让训练更稳定，还显著提升了验证集 F1 分数。
