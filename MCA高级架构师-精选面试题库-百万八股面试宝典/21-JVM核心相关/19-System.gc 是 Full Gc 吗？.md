参考回答：

System.gc 其实是做一次full gc操作。这一点可以根据 DisableExplicitGC 的注释说明来看。

注释：Tells whether calling System.gc() does a full GC。
