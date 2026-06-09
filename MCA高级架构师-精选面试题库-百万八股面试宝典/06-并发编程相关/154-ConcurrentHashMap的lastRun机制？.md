ConcurrentHashMap当中在扩容操作时，涉及到oldTable中是一个链表。

需要将oldTable中链表的数据迁移到newTable中。

lastRun机制就是链表迁移过程中涉及到的概念

在迁移过程中，如果链表尾部基于计算发现可以放到新数组的同一个位置上，此时就尾部位置的头放到新数组指定的索引位置就ok。后续的节点，不需要动

![](../assets/a898b49ee5b6a516.png)
