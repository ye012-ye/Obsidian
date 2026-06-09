这个是一个常识性的问题，一般是基于他引出更多的问题

从方法和功能的角度来聊。

- sleep是Thread中的静态方法，目的是让执行这个方法的线程进入TIMED\_WAITING，WAITING状态。
- wait是Object中的一个普通方法，目的是让持有锁的线程释放锁资源并且进入到TIMED\_WAITING，WAITING状态

sleep是由线程执行Thread.sleep方法，而wait是由持有锁的线程执行锁对象.wait方法。

sleep在进入阻塞状态时，不会释放锁资源（跟锁没关系）。 wait在进入阻塞状态时，会释放锁资源。
