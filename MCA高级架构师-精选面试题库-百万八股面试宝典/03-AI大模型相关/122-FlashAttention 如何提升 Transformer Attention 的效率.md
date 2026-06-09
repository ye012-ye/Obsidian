FlashAttention 的显存优化核心在于 **摒弃传统 Attention 中的全部中间矩阵存储**，通过 **块式计算（tiling）** 与 **反向重计算（recomputation）** 两大机制，显著降低显存占用，并提升计算速度。

以下是详细思路：

### 1. 传统 Attention 的显存瓶颈

标准 Transformer 在 Attention 计算中会完整生成 $QK^T$ 矩阵和 Softmax 权重矩阵（形状均为 $N×N$），显存开销为 $O(N^2)$。这些中间结果既用于前向传播，也为了反向传播而保留，尤其是在长序列上显存迅速爆炸。M

### 2. 分块计算（Tiling）

FlashAttention 将 Q、K、V 分割为小块（例如每块 128 个 token），每次加载一块到 GPU 的 on‑chip SRAM，再逐块执行局部 Attention 计算。不再生成完整的 $QK^T$ 矩阵，而是用累加器滚动汇总块级注意力输出，显存需求降为 $O(B\times N)$。此方式能减少对 HBM（高带宽显存）的频繁读写，典型可节省 90% 以上显存，速度提升约 2–4 倍。S  
这些原理基于对 GPU 内层存储层次（HBM 与 SRAM）的优化利用。

### 3. 重计算（Recomputation）

在前向传播阶段不会保存 $QK^T$ 和 Softmax 矩阵。反向传播时针对每个小块重新计算这些中间值，仅需存储 Softmax 的归一化因子等轻量级数据。这种策略通常增加约 10–15% 的计算量，但可换取 3–5 倍的显存节省，真正在长序列训练中释放显存瓶颈。B

### 4. 硬件感知优化

FlashAttention 的实现充分考虑 GPU 硬件特点：

- 分块大小设计与 SRAM 缓存容量匹配，使大部分计算在 SRAM 中完成，减少 HBM 访问；
- 将多个操作（MatMul、Mask、Softmax 等）融合成一个 CUDA 内核，减少多个读写步骤，对 HBM 的访问频率大幅降低。  
  这样的 “IO-aware” 设计是其能在延迟和资源利用上取得双重优势的关键。
