# 07 · DFS 与 BFS

> 图 / 树 / 网格类题目的两大基石。

---

## 1. 图的存储

### 1.1 邻接表（推荐，省空间）

```java
int n = 点数;
List<List<Integer>> g = new ArrayList<>();
for (int i = 0; i <= n; i++) g.add(new ArrayList<>());

// 加一条无向边
g.get(u).add(v);
g.get(v).add(u);
```

**带权图**：`List<int[]>`，每项是 `{邻居, 权重}`。

### 1.2 邻接矩阵（小图用）

```java
int[][] g = new int[n + 1][n + 1];
g[u][v] = g[v][u] = w;
```

只适合 n ≤ 500。

### 1.3 图 vs 网格

迷宫 / 方格图本身就是图，用 `int[][] grid` 存，四个方向走：
```java
int[] dx = {-1, 1, 0, 0};
int[] dy = {0, 0, -1, 1};
for (int d = 0; d < 4; d++) {
    int nx = x + dx[d], ny = y + dy[d];
    if (nx < 0 || nx >= n || ny < 0 || ny >= m) continue;
    ...
}
```

---

## 2. DFS（深度优先搜索）

### 2.1 原理

**一条路走到黑，走不通再回退。**

```
  图:            遍历顺序（DFS 从 1 开始）:
  
     1              1 → 2 → 4 → 5 → 3 → 6
    / \             
   2   3            先深入到底，再回溯
  / \   \
 4   5   6
```

### 2.2 递归模板

```java
boolean[] vis;

void dfs(int u) {
    vis[u] = true;
    // 做点什么（进入时）
    for (int v : g.get(u)) {
        if (!vis[v]) dfs(v);
    }
    // 做点什么（离开时）
}
```

### 2.3 栈模拟（防爆栈，Java 默认栈小）

```java
void dfsIter(int start) {
    ArrayDeque<Integer> stk = new ArrayDeque<>();
    stk.push(start);
    vis[start] = true;
    while (!stk.isEmpty()) {
        int u = stk.pop();
        // 做点什么
        for (int v : g.get(u)) {
            if (!vis[v]) { vis[v] = true; stk.push(v); }
        }
    }
}
```

> **Java 默认栈深度 ~1 万**，n=10⁵ 的链式图会栈溢出。重要比赛时要么开线程加栈，要么写迭代版。

### 2.4 经典应用

**a. 连通块计数**
```java
int cc = 0;
for (int i = 1; i <= n; i++) {
    if (!vis[i]) { dfs(i); cc++; }
}
```

**b. 网格岛屿数量（LC 200）**

```
grid:          找到所有 '1' 的连通块

1 1 0 0 0
1 1 0 1 0       → 三个岛屿
0 0 1 0 0
```

**c. 判环 / 拓扑排序 / 树 DFS**

---

## 3. BFS（广度优先搜索）

### 3.1 原理

**一层一层扩散。**

```
  图:         遍历顺序（BFS 从 1 开始）:

     1              1 → 2 → 3 → 4 → 5 → 6

    / \             先走完同层，再下一层
   2   3            
  / \   \
 4   5   6

层次：
  L0: {1}
  L1: {2, 3}
  L2: {4, 5, 6}
```

### 3.2 模板

```java
void bfs(int start) {
    ArrayDeque<Integer> q = new ArrayDeque<>();
    boolean[] vis = new boolean[n + 1];
    int[] dist = new int[n + 1];          // 到起点的最短步数
    q.offer(start);
    vis[start] = true;
    while (!q.isEmpty()) {
        int u = q.poll();
        for (int v : g.get(u)) {
            if (!vis[v]) {
                vis[v] = true;
                dist[v] = dist[u] + 1;
                q.offer(v);
            }
        }
    }
}
```

### 3.3 BFS 的神奇性质

**在边权全为 1 的图中，BFS 得到的 `dist` 就是最短路！**

原因：每次扩展一层，第一次访问到某点时，一定是最短。

### 3.4 多源 BFS

多个起点同时出发：初始化时把所有起点都放进队列。

**例：腐烂的橘子（LC 994）**
```
grid:
2 1 1     所有 2 同时开始扩散
1 1 0
0 1 1
```

把所有 2 入队，dist 计数，最后看 1 是否都被走到。

### 3.5 0/1 BFS（进阶）

边权只有 0 或 1：用 `ArrayDeque`，权 0 的边 push 前端，权 1 的 push 后端。相当于分层 BFS。
比 Dijkstra 快，O(n + m)。

---

## 4. DFS vs BFS 对比

```
             DFS                      BFS
结构        栈（递归也是栈）         队列
路径        深入到底                  按层扩散
空间        O(深度)                   O(宽度)
最短路      ❌（在无权图）           ✅（在无权图）
找所有路径  ✅                        ❌（难）
网格题      常用                      常用（求最短）
```

**选择建议**：
- 求"最短步数 / 最少操作次数" → BFS
- 枚举路径 / 求某种"存在性" → DFS
- 连通块 / 岛屿数量 → DFS 或 BFS 都行

---

## 5. 经典题深入讲解：岛屿数量（LC 200）

```
grid = 
1 1 0 0 0
1 1 0 1 0        答案 = 3
0 0 1 0 0
```

**DFS 版**：
```java
int numIslands(char[][] g) {
    int n = g.length, m = g[0].length, ans = 0;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++)
            if (g[i][j] == '1') { dfs(g, i, j); ans++; }
    return ans;
}
void dfs(char[][] g, int x, int y) {
    if (x < 0 || x >= g.length || y < 0 || y >= g[0].length || g[x][y] != '1') return;
    g[x][y] = '0';     // 原地标记已访问
    dfs(g, x+1, y); dfs(g, x-1, y);
    dfs(g, x, y+1); dfs(g, x, y-1);
}
```

**执行过程图示**（1 = 未访问陆地，0/X = 已访问）：
```
 起点 (0,0)：
 1 1 0 0 0     X 1 0 0 0     X X 0 0 0
 1 1 0 1 0  →  1 1 0 1 0  →  1 1 0 1 0 → ...
 0 0 1 0 0     0 0 1 0 0     0 0 1 0 0
 
 最终第一块全部变 X，ans=1；
 然后扫到 (1,3)='1'，开始第二块；
 再扫到 (2,2)='1'，第三块。
```

---

## 6. 扩展进阶：双向 BFS

当起点和终点都明确，且状态空间很大时，可以**两边一起搜**。

### 例：单词接龙 / 最少操作次数

普通 BFS：
```
start -> 一层 -> 一层 -> 一层 -> ... -> end
```

双向 BFS：
```
start -> ->          <- <- end
          中间相遇
```

如果每层分支数约是 k、答案长度是 d：
- 普通 BFS 约搜 `k^d`
- 双向 BFS 约搜 `2 * k^(d/2)`

差距会非常大。

**写法要点**：
1. 两个队列 / 两个 visited，分别从 `start`、`end` 出发
2. 每次优先扩展**当前更小**的那一边
3. 一旦新状态出现在对面的 visited 里，就说明相遇成功

这类题本质仍是 BFS，只是把"一层一层扩散"改成了"两边夹逼"。

---

## 7. 踩坑提醒 ⚠️

1. **vis 数组忘记置 true** → 死循环 / 栈溢出。
2. **递归栈太深**：n > 10⁵ 时写迭代版，或加：
   ```java
   new Thread(null, () -> { /* main code */ }, "main", 256L << 20).start();
   ```
3. **BFS 的 `vis` 要在入队时立刻标记**，不是出队时。否则同点会重复入队。
4. **网格 4 方向走**：注意对角题目是 8 方向。
5. **BFS 求最短路只对无权图成立**。带权用 Dijkstra（见 10 章）。

---

## 8. 练习推荐

| 题目 | 难度 | 类型 |
|------|------|------|
| LC 200 岛屿数量 | 🟡 | DFS / BFS |
| LC 695 岛屿的最大面积 | 🟡 | DFS |
| LC 994 腐烂的橘子 | 🟡 | 多源 BFS |
| LC 133 克隆图 | 🟡 | DFS + HashMap |
| LC 127 单词接龙 | 🔴 | BFS |
| 洛谷 P1162 填涂颜色 | 🟡 | 从边界 BFS |

---

**下一章 →** [08-动态规划入门](08-动态规划入门.md)
