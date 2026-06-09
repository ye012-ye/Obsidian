ConcurrentHashMap是懒加载的机制，而且大多数的框架组件都是懒加载的~

基于CAS来保证初始化线程安全的，这里不但涉及到了CAS去修改sizeCtl的变量去控制线程初始化数据的原子性，同时还使用了DCL，外层判断数组未初始化，中间基于CAS修改sizeCtl，内层再做数组未初始化判断。

![](../assets/7e14cf18ad77731d.png)
