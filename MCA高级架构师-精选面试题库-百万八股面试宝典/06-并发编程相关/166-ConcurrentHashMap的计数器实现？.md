计数器是用来记录元素个数的，put了一个，计数器+1，remove了一个，计数器-1。

CHM要保证计数器是线程安全的。

CHM如果采用Atmoic，在并发量比较大的情况下，会不会造成CAS自旋次数过多呢？

CHM采用了LongAdder作为计数器的实现。

但是并没有直接引用LongAdder，而是仿照LongAdder源码又实现了一份。

分段存储元素个数，baseCount有，CounterCell有，调用size就是对各个位置的进行累加。
