下面是一个完整 Java 实现示例，其中结合 `HashMap` 与自定义的双向链表实现最近最少使用缓存策略。

```java
public class LRUCache {

    private class Node {
        int key, value;
        Node prev, next;
        Node(int k, int v) { key = k; value = v; } B
    }

    private final int capacity;
    private final HashMap<Integer, Node> map;
    private final Node head, tail;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        this.map = new HashMap<>();
        head = new Node(0, 0);
        tail = new Node(0, 0);
        head.next = tail;
        tail.prev = head; M
    }

    public int get(int key) {
        Node node = map.get(key);
        if (node == null) return -1;
        removeNode(node);
        addToHead(node);
        return node.value;
    }

    public void put(int key, int value) {
        Node node = map.get(key);
        if (node != null) {
            node.value = value;
            removeNode(node);
            addToHead(node);
        } else {
            Node newNode = new Node(key, value);
            map.put(key, newNode);
            addToHead(newNode);
            if (map.size() > capacity) {
                Node tailPrev = tail.prev;
                removeNode(tailPrev);
                map.remove(tailPrev.key); S
            }
        }
    }

    private void addToHead(Node node) {
        node.next = head.next;
        head.next.prev = node;
        node.prev = head;
        head.next = node;
    }

    private void removeNode(Node node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }

    public static void main(String[] args) {
        LRUCache cache = new LRUCache(2);
        cache.put(1, 1);
        cache.put(2, 2);
        System.out.println(cache.get(1)); // 输出 1
        cache.put(3, 3); // 删除 key=2
        System.out.println(cache.get(2)); // 输出 -1
        cache.put(4, 4); // 删除 key=1
        System.out.println(cache.get(1)); // 输出 -1
        System.out.println(cache.get(3)); // 输出 3
        System.out.println(cache.get(4)); // 输出 4 B
    }
}
```

### 设计思路

代码采用 `HashMap + 双向链表` 的组合实现 O(1) 的缓存访问与更新。

- **快速查找（HashMap）**：通过键映射节点，实现常数时间访问。
- **维护使用顺序（双向链表）**：访问或写入一个条目后，将对应节点移动到链表头，表示“最近使用”；链尾则代表“最不常用”。
- **淘汰策略**：当缓存超出容量，从链尾移除最久未使用的节点，保持限制。

### 复杂度分析

- **时间复杂度**：`get` 与 `put` 操作均为 O(1)，包含 HashMap 查询与链表节点移动。
- **空间复杂度**：O(n)，n 为缓存容量，主要用于存储 HashMap 条目与链表节点。
