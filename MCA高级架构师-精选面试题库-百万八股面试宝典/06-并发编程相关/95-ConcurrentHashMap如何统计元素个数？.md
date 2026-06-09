首先ConcurrentHashMap是线程安全的集合，统计元素个数，肯定要确保线程安全。

计算元素个数，无非是++，--。

确保++，--线程安全，还要有效率。

这里ConcurrentHashMap选择的就是LongAdder，首先基于CAS对元素做++，--操作，确保线程安全。并且LongAdder除了ConcurrentHashMap记录元素个数的baseCount外，同时也准备了一个CounterCell数组，每一个CounterCell里都有一个value记录元素个数。这样CAS就可以针对多个位置执行，以尽量减少CAS的空转情况。
