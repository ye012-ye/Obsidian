当问到了乐观锁和悲观锁的时候，就从锁分类维度的展开聊。

乐观悲观：

- 乐观：认为没有并发情况，直接动手！看成功失败！不阻塞线程。CAS
- 悲观：认为必然有并发，先尝试拿锁资源，再动手，拿不到锁资源就阻塞线程。lock，synchronized

互斥共享：

- 互斥：只能有一个线程同时持有一把锁。 synchronized，lock
- 共享：同一时间，可以有多个线程持有一把锁，一般是针对读写锁的实现。ReentrantReadWriteLock，StampedLock。

重入非重入：同一个线程持有一把锁的时候，再次竞争这个锁资源，是可以直接获取的。

**Ps：非重入锁在Java中只有线程池里的Worker对象是非重入的，但是这个Worker的锁不对外提供，是内部的一个机制。**

公平非公平：是否存在插队的情况，synchronized和lock锁默认都是非公平锁（其实不是真插队，是上来直接抢，抢到走人，抢不到还是乖乖的去排队）。公平锁就是锁被持有，或者有排队的，就直接排到最后面，不抢。

**Ps：公平锁的实现在构建ReentrantLock对象时，有参构造里传入true即可。**

---

**细聊一下自旋锁和CAS？**

**自旋锁这个名词是synchronized内部的。在synchronized中有个轻量级锁的概念，他会多次的执行CAS去尝试获取锁资源，而这个多次CAS就被称为自旋锁。**

而CAS本质在Java中是一个方法，Unsafe类中的一个native方法。

本质是在oldValue和当前值一样的情况下，将olaValue修改为newValue

```java
// CAS的本质是针对某个对象中的某个属性从oldValue修改为newValue
var1：哪个对象？
var2：属性在这个对象中的偏移量。
var4：oldValue
var5：newValue
compareAndSwapObject(Object var1, long var2, Object var4, Object var5);
```

CAS只是在修改一个属性时，确保线程安全，无法保证一段代码的线程安全。

同时compareAndSwapObject方法是native修饰的，他的本质是利用的CPU的指令来实现的，cmpxchg。

**Compare And Exchange（cmpxchg）**

---

**CAS的几个问题：**

- ABA：在多线程并发的情况下，要修改的值，本来不符合预期，但是修改的时候，因为其他线程的操作，导致符合预期了，就直接修改了。不是咱想要的。解决的方式也很简单，额外加一个版本好即可。而且Java中已经提供了对应的工具类，AtomicStampedReference，提供了除了值之外的额外的版本号可以指定。  
  **Ps：ABA不一定是问题，就好比你的银行卡，你花了10块，又存了10块，之前钱没问题，就是ok的。具体看业务，比如刚才举例的二手车问题。**
- 自旋次数过多：因为CAS不会挂起线程，可以一直执行，比如AtomicInteger，他的底层是一个do-while循环，一直CAS，直到成功为止，如果一直不成功，就会一直占用CPU资源，一直执行。。
- 无法保证一段代码的原子性，想保证得封装，不过Java封装好了，synchronized，lock锁都是基于CAS实现的。
