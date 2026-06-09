我们使用 `List<Integer>` 作为底层结构，数组索引代表完全二叉树节点，根在 index 0。下面是核心实现：M

```java
class MinHeap {
    private List<Integer> heap = new ArrayList<>();

    // 插入元素：添加到末尾后上浮
    public void insert(int val) {
        heap.add(val);
        int i = heap.size() - 1;
        while (i > 0) {
            int p = (i - 1) / 2;
            if (heap.get(i) >= heap.get(p)) break;
            Collections.swap(heap, i, p);
            i = p;
        }
    }

    // 获取最小元素（不删除）
    public int peek() {
        if (heap.isEmpty()) throw new IllegalStateException("Heap is empty");
        return heap.get(0);
    }

    // 移除并返回最小元素：用末尾元素替换根后下沉
    public int poll() {
        if (heap.isEmpty()) throw new IllegalStateException("Heap is empty");
        int min = heap.get(0);
        int last = heap.remove(heap.size() - 1);
        if (!heap.isEmpty()) {
            heap.set(0, last);
            heapify(0);
        }
        return min;
    }

    // 下沉操作：保持堆序性
    private void heapify(int i) {
        int n = heap.size();
        while (true) {
            int l = 2 * i + 1, r = 2 * i + 2, smallest = i;
            if (l < n && heap.get(l) < heap.get(smallest)) smallest = l;
            if (r < n && heap.get(r) < heap.get(smallest)) smallest = r;
            if (smallest == i) break;
            Collections.swap(heap, i, smallest);
            i = smallest;
        }
    }
}
```

S

## 代码说明：

- **存储方式**：堆结构映射到数组索引，根节点是 `heap.get(0)`。
- `insert` **操作**：插入尾部然后通过与父节点交换（上浮）保持最小堆性质。时间复杂度：O(log n)。
- `peek` **操作**：直接返回索引 0 的值，时间复杂度：O(1)。
- `poll` **操作**：删除根节点，用最后一个元素补位后进行下沉（与子节点交换）。时间复杂度：O(log n)。
- **空间复杂度**：O(n)，n 是堆中元素数量。

B
