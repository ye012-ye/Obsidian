CPU缓存可见性的问题，就是在缓存行数据发生变化时，会发出通知，告知其他内核缓存行数据设置为无效。

但是因为CPU厂商为了提升CPU的执行效率，经常会追加一些优化的操作，StoreBuffer，Invalidate Queue。这些就会导致MESI协议通知受到影响，同步数据没那么及时。

所以CPU内部提供了一个指令， **lock前缀指令** ，如果使用了lock前缀指定去操作一些变量，此时会将数据立即写回到主内存（JVM），必然会触发MESI协议，类似StoreBuffer，Invalidate Queue的缓存机制也会立即处理。
