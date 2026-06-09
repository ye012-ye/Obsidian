单词不一样

lock需要new着用，sync关键字，只能同步代码块和同步方法用

lock需要手动释放，sync不需要手动释放

lock基于AQS实现，sync基于对象实现，重量级锁采用ObjectMonitor

lock支持公平和非公平锁，sync只是非公平锁

lock基于Condition的await和signal做挂起和唤醒，sync通过wait和notify做这个操作

…………
