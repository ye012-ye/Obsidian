Log Buffer是存储要写入到磁盘上的日志文件的一片内存区域。主要是redo log。

默认占用16M的大小。可以用过 `innodb_log_buffer_size` 参数调整。

他的目的很简单，就是在你做写操作时，尽量减少日志写入磁盘时的IO损耗，减少IO的次数……
