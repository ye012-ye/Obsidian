DCL去做的，锁的实现是基于CAS的方式去玩的。

CHM在初始化数组时，sizeCtl == -1

要初始化数组的线程需要基于CAS成功的将sizeCtl改为-1，才可以去执行初始化操作。

外层while循环判断数组未初始化，基于CAS加锁，然后在内层基于if再次判断数组未初始化

那么此时就可以直接

```plain
Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[初始长度];
```
