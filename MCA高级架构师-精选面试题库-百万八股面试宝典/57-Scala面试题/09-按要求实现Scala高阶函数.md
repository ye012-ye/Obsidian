请参照Scala中常见的map函数实现一个名为mymap的高阶函数。mymap接收两个参数值，第一个为函数(x:Int)=>3\*x ，第二个为Int型数据。在mymap函数体内将第一个参数作用与第二个参数。

|  |
| --- |
| object ScalaTest {  // 定义高阶函数 mymap，接收一个函数和一个整数作为参数  def mymap(f: Int => Int, i: Int): Int = {  f(i) // 将函数 f 应用于参数 i  }    def main(args: Array[String]): Unit = {  // 调用 mymap，将匿名函数 (x: Int) => 3 \* x 和整数 10 作为参数  println(mymap(x => 3 \* x, 10)) // 输出结果: 30  }  } |
