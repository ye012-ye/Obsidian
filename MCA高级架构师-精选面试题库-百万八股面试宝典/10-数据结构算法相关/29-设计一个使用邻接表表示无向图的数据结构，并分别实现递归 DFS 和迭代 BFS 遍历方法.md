我们通过邻接表来组织图结构，提高邻居遍历效率，并提供递归 DFS 和基于队列的 BFS 方法。

#### 1. 邻接表表示图

```java
class Graph {
    private Map<Integer, List<Integer>> adj = new HashMap<>();

    public void addEdge(int u, int v) {
        adj.computeIfAbsent(u, k -> new ArrayList<>()).add(v);
        adj.computeIfAbsent(v, k -> new ArrayList<>()).add(u);
    }
}
```

这里 `adj` 中的每个键代表一个顶点，值为它的邻接顶点列表。邻接表是稀疏图最常用的存储方式之一。M

#### 2. 递归 DFS

```java
public void dfs(int start) {
    Set<Integer> seen = new HashSet<>();
    dfsRec(start, seen);
}

private void dfsRec(int u, Set<Integer> seen) {
    seen.add(u);
    System.out.print(u + " ");
    for (int v : adj.getOrDefault(u, List.of())) {
        if (!seen.contains(v)) dfsRec(v, seen);
    }
}
```

这个方法利用系统调用栈逐层深入，先处理当前节点再递归访问未访问的邻居。S

#### 3. 迭代 BFS

```java

public void bfs(int start) {
    Set<Integer> seen = new HashSet<>();
    Queue<Integer> queue = new LinkedList<>();
    seen.add(start);
    queue.offer(start);

    while (!queue.isEmpty()) {
        int u = queue.poll();
        System.out.print(u + " ");
        for (int v : adj.getOrDefault(u, List.of())) {
            if (!seen.contains(v)) {
                seen.add(v);
                queue.offer(v);
            }
        }
    }
}
```

BFS 使用队列层层展开，从起始点出发，按层访问完整个图。B

#### 4. 复杂度分析

- **时间复杂度**：DFS/BFS 均为 O(V+E)O(V + E)O(V+E)。
- **空间复杂度**：邻接表 O(V+E)O(V + E)O(V+E)、DFS 递归栈/visited 集合要 O(V)O(V)O(V)、BFS 队列 + seen 集合也为 O(V)O(V)O(V)。
