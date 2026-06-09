sizeCtl是用于初始化数组和做扩容是的一个控制字段。

不一样的值，代表不同的意思：

- sizeCtl == -1：代表ConcurrentHashMap正在初始化数组。
- sizeCtl < -1：代表ConcurrentHashMap正在初始化扩容
- sizeCtl == 0：代表默认状态，啥事没有。
- sizeCtl > 0：有可能代表两个意思：

- 数组没初始化时：可能代表ConcurrentHashMap初始化数组时的长度。
- 数组已经初始化：sizeCtl的值代表下次扩容的阈值。
