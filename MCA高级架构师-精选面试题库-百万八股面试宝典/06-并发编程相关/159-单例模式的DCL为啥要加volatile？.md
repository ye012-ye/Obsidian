伪代码

DCL就是Double Check Lock，就是俩if加一个锁

指令重排可能会导致下面的DCL出现问题

```java
private static Instance instance = null;
public static Instance getInstance(){
  if(instance == null){
    sync(xxx){
      if(instance == null){
        instance = new Instance();
        // new操作，分为三个事情，1开辟内存空间，2初始化内部属性，3将地址给予instance引用
        // 因为指令重排的原因，可能会将原有的123顺序，修改为132
        // 先执行了13，但是2还没执行，instance有了指向
      }
    }
  }
  return instance;
}
```

一模一样的操作，只需要在属性上追加volatile

```java
private volatile static Instance instance = null;
public static Instance getInstance(){
  if(instance == null){
    sync(xxx){
      if(instance == null){
        instance = new Instance();
      }
    }
  }
  return instance;
}
```

##
