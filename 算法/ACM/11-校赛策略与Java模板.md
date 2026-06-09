# 11 · 校赛策略与 Java 模板

> 5 小时比赛怎么打？Java 选手怎么写才不 TLE？本章是临场"保命手册"。

---

## 1. 五小时打赛节奏

```
 0:00 - 0:15  全员读题，标签分类：
              🟢 一眼签到   🟡 有思路   🔴 不会 / 难   ⬛ 题面晦涩

 0:15 - 1:30  做完所有 🟢 和 简单 🟡。目标：过 3~5 题。

 1:30 - 3:00  啃 🟡 中等题，该讨论讨论，该对拍对拍。
              ⚠️ 不要死扣一道题超过 40 分钟！切题更重要。

 3:00 - 4:00  冲击 🔴。
              封榜（剩余 1 小时）后专注自己的题，别看榜。

 4:00 - 5:00  封榜期：稳定 AC 已有进度 > 冒险开新题。
              还剩大于 30 分钟没提交，再考虑新题。
```

---

## 2. 罚时管理

> **每个 WA = +20 分钟**，**过题数相同时罚时少的赢**。

### 规则：
1. **提交前先过所有自己手造的样例** —— 没有自信就别点"提交"。
2. **把边界数据都测一遍**：
   - n = 0, 1
   - 全部相同
   - 极值（10⁹, -10⁹）
   - 需要 long 的情况
3. **WA 后先看样例再写代码**，别瞎改。
4. **TLE**：看数据范围，可能是复杂度高一档，或 Java 需要快读。
5. **RE**：大概率是越界 / 空栈 pop / 栈溢出。

---

## 3. Java 快读模板（校赛必备）

Scanner 在 n=10⁵+ 的题里**会 TLE**。用 `BufferedReader` + `StreamTokenizer`：

```java
import java.io.*;
import java.util.*;

public class Main {
    static StreamTokenizer in = new StreamTokenizer(new BufferedReader(new InputStreamReader(System.in)));
    static PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(System.out)));

    static int nextInt() throws IOException { in.nextToken(); return (int) in.nval; }
    static long nextLong() throws IOException { in.nextToken(); return (long) in.nval; }
    static double nextDouble() throws IOException { in.nextToken(); return in.nval; }

    public static void main(String[] args) throws IOException {
        int n = nextInt();
        int[] a = new int[n];
        for (int i = 0; i < n; i++) a[i] = nextInt();
        // ... 计算 ...
        out.println(ans);
        out.flush();
    }
}
```

**注意**：
- `StreamTokenizer` 的 `nval` 是 double，超过 2^53 会丢精度。大数要用下面的版本：

```java
// 大数版
static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
static StreamTokenizer in = new StreamTokenizer(br);

// 读长整型字符串（防精度丢失）
static long nextLong() throws IOException {
    in.nextToken();
    return Long.parseLong(in.sval != null ? in.sval : String.valueOf((long) in.nval));
}
```

或者用原始 BufferedReader 手动 split：
```java
static String[] readLine() throws IOException {
    return br.readLine().trim().split("\\s+");
}
```

---

## 4. Java 踩坑大全

### 4.1 **`int` 溢出**
```java
int a = 1_000_000, b = 1_000_000;
int c = a * b;   // 溢出，c 不是 10^12
long c = (long) a * b;   // 正确，强转一侧
```

**口诀**：两数乘积可能 > 2×10⁹，就**其中一个强转 long**。

### 4.2 **Integer vs int**
```java
Integer x = 128, y = 128;
x == y;          // false！装箱后是对象比较
x.equals(y);     // true
```
**永远用 `equals` 比较 Integer**。

### 4.3 **HashMap 的 merge**
```java
cnt.merge(key, 1, Integer::sum);   // += 1
```
比 `cnt.put(k, cnt.getOrDefault(k, 0) + 1)` 短且快。

### 4.4 **ArrayList 转 int[]**
```java
int[] arr = list.stream().mapToInt(Integer::intValue).toArray();
```

### 4.5 **输出大量数据要 StringBuilder**
```java
StringBuilder sb = new StringBuilder();
for (int i = 0; i < n; i++) sb.append(ans[i]).append('\n');
out.print(sb);
```
`System.out.println` n 次会被慢死。

### 4.6 **Arrays.sort 对 int[] 不稳定且有坑**
对抗数据可能把它卡成 O(n²)。解法：把 `int[]` 装成 `Integer[]` 再 sort（变成归并排序）。
或者：
```java
// shuffle 一下再 sort
List<Integer> l = new ArrayList<>(n);
for (int x : a) l.add(x);
Collections.shuffle(l);
Collections.sort(l);
```

### 4.7 **栈深度**
Java 默认 main 线程栈 512KB，递归 ~1 万层会 SOF。解法：
```java
public static void main(String[] args) {
    new Thread(null, ACM::run, "main", 1L << 28).start();   // 256MB 栈
}
static void run() { /* 真正的 main 代码 */ }
```

---

## 5. 必背代码段（打印出来带进考场）

### 5.1 排序自定义
```java
Arrays.sort(arr, (a, b) -> a[0] != b[0] ? a[0] - b[0] : b[1] - a[1]);
// 第一列升序，相同则第二列降序
```

### 5.2 最大/最小
```java
Arrays.stream(a).max().getAsInt();
Collections.max(list);
```

### 5.3 GCD / LCM
```java
long gcd(long a, long b) { return b == 0 ? a : gcd(b, a % b); }
long lcm(long a, long b) { return a / gcd(a, b) * b; }
```

### 5.4 快速幂
```java
long pow(long a, long b, long mod) {
    long ans = 1 % mod; a %= mod;
    while (b > 0) {
        if ((b & 1) == 1) ans = ans * a % mod;
        a = a * a % mod;
        b >>= 1;
    }
    return ans;
}
```

### 5.5 判素数
```java
boolean isPrime(long n) {
    if (n < 2) return false;
    for (long i = 2; i * i <= n; i++) if (n % i == 0) return false;
    return true;
}
```

### 5.6 欧拉筛 O(n)（预处理 ≤ N 的所有素数）
```java
boolean[] notP = new boolean[N + 1];
int[] prime = new int[N + 1]; int pn = 0;
for (int i = 2; i <= N; i++) {
    if (!notP[i]) prime[pn++] = i;
    for (int j = 0; j < pn && (long)i * prime[j] <= N; j++) {
        notP[i * prime[j]] = true;
        if (i % prime[j] == 0) break;
    }
}
```

---

## 6. 现场对拍

写了个算法觉得对，又不敢交？**对拍**：
1. 写一个**暴力版**（一定正确、慢）
2. 写一个**随机数据生成器**
3. 两个都跑，比对输出

```java
// 简化版伪代码
for (int i = 0; i < 1000; i++) {
    int[] data = gen();             // 随机生成
    int a = myAlgo(data);
    int b = bruteForce(data);
    if (a != b) { print(data); break; }
}
```

---

## 7. 本次校赛（暨大 2026）的特别提醒

从赛事公告看：
- **比赛平台：牛客竞赛 ac.nowcoder.com**
- 题面中文，共约 12 道
- 封榜：最后 1 小时
- **WA 罚 20 分钟**
- 可带纸质资料（打印本笔记 + 常见模板）

建议**比赛前打印**：
1. 本章（Java 模板 & 快读）
2. 04-二分查找.md（二分板子）
3. 06 的滑窗/单调队列模板
4. 08 的 DP 状态设计小抄
5. 10 的并查集模板
6. 12 的最短路模板
7. 14 的树状数组模板
8. 16 的 KMP / Trie 小抄
9. 17 的数论模板

---

## 8. 扩展进阶：赛中 Debug 顺序图

比赛里最怕的不是不会写，而是**错了以后乱改**。推荐固定排查顺序：

```
样例不过
  ↓
先手推 1 组最小数据
  ↓
看是：
- 越界 / 空指针 / 空栈？   → 边界问题
- 少 1 / 多 1？           → 下标、区间问题
- 大数据才错？            → long / 复杂度问题
- 某些点 WA？             → 贪心 / 判定条件问题
  ↓
再决定改哪里
```

更具体一点：
1. **先看输入输出**：读错数据比算法错更常见
2. **再看边界**：`n=1`、空区间、重复值、负数
3. **再看状态更新顺序**：尤其滑窗、DP、二分
4. **最后才怀疑思路**

这套顺序能避免"看到 WA 就东改一行、西改一行"。

---

## 9. 临场心态

- **前 15 分钟集体读题，不要急着写代码**。每个人读 2~3 道，互相分享思路。
- **一题卡住超 30 分钟就切题**。
- **WA 的那一刻不要马上改**，先手推个反例。
- **榜单看前 1 小时**就行，过了 30 分钟就别再反复刷榜。
- **厕所和补水**：5 小时很长，开场先去一次厕所 + 灌好水。
- **队友吵架别气**：结束之后再算账 🙂

---

## 10. 最后的话

算法练习没有捷径，但**有顺序**：
1. 先做本笔记后面附的 LC 链接题
2. 掌握每章一个典型板子
3. 每周模拟一次，5 小时打 5 题就是稳的开局

**校赛不是终点，是练兵**——Have fun！🚀

---

**进阶继续 →** [12-最短路与Dijkstra](12-最短路与Dijkstra.md)  
**🏠 回到 [README](README.md)**
