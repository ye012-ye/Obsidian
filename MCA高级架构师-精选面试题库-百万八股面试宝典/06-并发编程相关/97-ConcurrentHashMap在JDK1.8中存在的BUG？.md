在扩容的地方，有协助扩容的判断，在这个判断中，中间两个个判断都是毫无意义的。

```java
// 第一个判断，是为了确保协助扩容的线程，和正在扩容的线程的长度是一致的。
if ((sc >>> RESIZE_STAMP_SHIFT) != rs || 
    // 正常这么写：sc == rs << RESIZE_STAMP_SHIFT + 1 ,目的是为了判断，当前扩容是否已经到了最后的检查阶段。BUG ~~~
    sc == rs + 1 || 
    // 正常这么写：  sc == rs << RESIZE_STAMP_SHIFT  + MAX_RESIZERS,目的是为了判断，当前过来协助扩容的线程，是否已经到了最大值。  BUG~~~
    sc == rs + MAX_RESIZERS || 
    // 后面这俩不是BUG~
    (nt = nextTable) == null ||
    transferIndex <= 0)
    break;
```

在协助扩容前，有几个判断，主要是判断扩容是否结束，以及协助扩容的线程是否已经达到最大值的这两个判断，这两个判断没有将扩容标识戳做左移操作，就直接与sizeCtl做判断了，这种判断是没有任何意义的。
