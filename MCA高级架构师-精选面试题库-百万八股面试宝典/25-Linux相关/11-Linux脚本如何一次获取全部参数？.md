Shell 脚本可以通过特殊变量获取传递的参数：

|  |  |
| --- | --- |
| **特殊变量** | **含义** |
| $0 | 脚本名称 |
| $1 | 第一个参数 |
| $2 | 第二个参数 |
| $@ | 所有参数，按独立的字符串形式处理 |
| $\* | 所有参数，作为一个整体字符串处理 |
| $# | 参数个数 |

假设脚本名为/root/example.sh，内容如下：

|  |
| --- |
| #!/bin/bash  echo "脚本名称：$0"  echo "第一个参数：$1"  echo "第二个参数：$2"  echo "所有参数：$@"  for arg in "$@"; do  echo "参数：$arg"  done  echo "所有参数：$\*"  for arg in "$\*"; do  echo "参数：$arg"  done  echo "参数个数：$#" |

执行脚本：

|  |
| --- |
| sh /root/example.sh arg1 arg2 arg3 arg4 |

运行结果：

|  |
| --- |
| 脚本名称：example.sh  第一个参数：arg1  第二个参数：arg2  所有参数：arg1 arg2 arg3 arg4  参数：arg1  参数：arg2  参数：arg3  参数：arg4  所有参数：arg1 arg2 arg3 arg4  参数：arg1 arg2 arg3 arg4  参数个数：4 |
