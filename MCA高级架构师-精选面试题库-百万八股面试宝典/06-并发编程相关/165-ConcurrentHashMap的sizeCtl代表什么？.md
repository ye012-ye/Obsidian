sizeCtl是用来控制数据的一些操作的。

sizeCtl > 0：

- 可能是下次扩容的阈值
- 可能是初始化数组的长度

sizeCtl == 0：数组还没初始化，并且没设置初始长度，默认16。

sizeCtl == -1：数组正在初始化

sizeCtl  -1：数组正在扩容

**初始化修改sizeCtl：**

![](../assets/235f6dda9fb94b37.png)

**扩容修改sizeCtl：**

![](../assets/1d405c8341063632.png)
