基于JDK1.8，HashMap中有如下核心方法：M

### ​`get(Object key)`

- 调用 `hash(key)` 根据 key 的 `hashCode()` 并扰动得到最终 hash 值；
- 定位桶索引 `index = (n−1)&hash` 并取出首节点；
- 若首节点匹配则返回；
- 否则，若是链表则遍历查找或树结构则调用 `getTreeNode()` 进行对比查找。

### `put(K key, V value)`

- 通过 `hash(key)` 计算 hash；
- 若桶为空直接插入新 `Node`；
- 若已存在节点，先比较 key 是否相同，若相同则替换 value；S
- 若冲突且为链表，遍历链表尾部插入新节点，并在长度 ≥ 8 时调用 `treeifyBin()` 转为红黑树；
- 若是树节点则直接调用 `putTreeVal()` 插入 。

### `resize()`

- 当元素总数超过 `threshold = capacity × loadFactor` 时触发扩容；
- 容量翻倍，新建数组；
- 旧数组元素逐个迁移到新桶中：

- 若为单节点链表，直接计算 `(e.hash & oldCap)` 决定是否索引不变或偏移 `oldCap`；
- 若链表较长或树结构则分别处理。B
