Java 集合框架围绕几个核心接口构建，每种接口代表不同的数据结构抽象，适合对应的应用场景。主要接口如下：

- `Collection`：集合层次结构的根接口，继承自 `Iterable`，定义添加、删除、遍历、判断等通用操作。所有 List、Set、Queue 都扩展自它。M
- `List`：有序可重复集合，支持通过索引访问元素。常见实现有 `ArrayList`（动态数组）、`LinkedList`（双向链表）、`Vector`。适合需要保留插入顺序或频繁查找的场景。S
- `Set`：不允许重复元素的集合，无序。主流实现包括 `HashSet`（基于哈希）、`LinkedHashSet`（保留插入顺序）、`TreeSet`（红黑树、有序）。
- `Queue`：先进先出队列接口，支持入队、出队操作。典型实现为 `LinkedList`、`PriorityQueue`（优先级队列）、`ArrayDeque`（双端队列）。适用于任务调度、缓冲区等场景。B
- `Map`：键-值对映射接口，不继承自 Collection。每个键唯一。常见实现有 `HashMap`（无序散列）、`LinkedHashMap`（保留顺序）、`TreeMap`（按键排序）。
- **扩展接口**：

- `SortedSet` **/** `NavigableSet`：用于支持排序操作的 Set，比如 `TreeSet`。
- `SortedMap` **/** `NavigableMap`：用于按键排序的 Map，比如 `TreeMap`。
- `Deque`：双端队列，支持两端插入/删除。典型实现为 `ArrayDeque`、`LinkedList`。
- `ConcurrentMap` 等并发专用接口：如 `ConcurrentHashMap` 适用于多线程环境。
