Java中处理异常的一些机制：

- try-catch：捕获异常的
- throw：抛出异常的
- throws：声明方法抛出异常
- SpringMVC有异常处理器：全局的异常处理

聊第二个问题，可以先说一下异常的结构，顶级父类，Throwale，下面俩子类Error和Exception其中Execption里分为运行时异常（unchecked），检查时异常（checked）

- checked：就是在编译时期，就存在的，当咱们做一些操作时，比如IO操作，文件可能不存在，提前向上抛出IOException。
- unchecked：运行时异常，就是程序运行后，在执行代码时，可能会出现的异常，比如NPE，索引越界等等。。

自定义异常这，记住，一定是继承RuntimeException，这样才能更好的适配Spring的声明式事务，如果抛出的不是RuntimeException， Spring声明式事务会失效。

自定义异常就是自己在可能发生异常的地方，经过一定的逻辑判断，就可以手动抛出异常，自定义异常中最好存储code和message信息，以便在抛出异常后，可以快速定个位到哪个逻辑出现的什么问题。code和message可以在枚举中维护。
