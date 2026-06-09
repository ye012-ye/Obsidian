因为在addWaiter方法中，需要先将当前节点的prev之前前继节点，然后基于CAS将tail指向当前节点，最后才是将前继节点的next指向当前节点。

其次，取消排队时，cancelAcquire会将node的next指向自己。

结论，next指针不保证有效。
