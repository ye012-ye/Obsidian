除此之外就是MyISAM，5.1版本时，那也是默认的存储引擎。。。

主要来聊这两个存储引擎的区别，区别其实特别多……………………

在8.x的InnoDB和MyISAM中，支持的特性区别。

> - 关于聚簇索引的支持，InnoDB支持聚簇索引，MyISAM不支持聚簇索引
> - 关于数据缓存的支持，InnoDB支持数据缓存扔Buffer Pool，MyISAM不支持。
> - 关于外键的支持，InnoDB支持外键，MyISAM不支持外键。
> - 关于Hash索引，InnoDB和MyISAM都不支持。但是InnoDB支持一个AHI的自适应hash索引。
> - 关于锁的支持，InnoDB支持行锁，而MyISAM只支持表锁。
> - 关于MVCC，InnoDB支持，MyISAM不支持。
> - 关于存储容量的限制，InnoDB可以支持到64TB，而MyISAM支持到256TB
> - 关于事务，InnoDB支持，MyISAM不支持。

InnoDB：

![](../assets/7758d3cf93b15012.png)

MyISAM：

![](../assets/47daddef8a28d9c2.png)
