以下 Java 程序展示了三种深度优先遍历方式（前序、中序、后序），分别实现了递归与栈模拟的非递归版本。M

```java
import java.util.*;

public class TreeTraversal {

    static class TreeNode {
        int val;
        TreeNode left, right;
        TreeNode(int v) { val = v; left = right = null; }
    }

    // 递归版
    public static void preorderRec(TreeNode node) {
        if (node == null) return;
        System.out.print(node.val + " ");
        preorderRec(node.left);
        preorderRec(node.right);
    }

    public static void inorderRec(TreeNode node) {
        if (node == null) return;
        inorderRec(node.left);
        System.out.print(node.val + " ");
        inorderRec(node.right);
    }

    public static void postorderRec(TreeNode node) {
        if (node == null) return;
        postorderRec(node.left);
        postorderRec(node.right);
        System.out.print(node.val + " ");
    }

    // 非递归版
    public static void preorderIter(TreeNode root) {
        if (root == null) return;
        Stack<TreeNode> st = new Stack<>();
        st.push(root);
        while (!st.isEmpty()) {
            TreeNode cur = st.pop();
            System.out.print(cur.val + " ");
            if (cur.right != null) st.push(cur.right);
            if (cur.left != null) st.push(cur.left);
        }
    }

    public static void inorderIter(TreeNode root) {
        Stack<TreeNode> st = new Stack<>();
        TreeNode cur = root;
        while (cur != null || !st.isEmpty()) {
            while (cur != null) {
                st.push(cur);
                cur = cur.left;
            }
            cur = st.pop();
            System.out.print(cur.val + " ");
            cur = cur.right;
        }
    }

    public static void postorderIter(TreeNode root) {
        if (root == null) return;
        Stack<TreeNode> st = new Stack<>(), out = new Stack<>();
        st.push(root);
        while (!st.isEmpty()) {
            TreeNode cur = st.pop();
            out.push(cur);
            if (cur.left != null) st.push(cur.left);
            if (cur.right != null) st.push(cur.right);
        }
        while (!out.isEmpty()) {
            System.out.print(out.pop().val + " ");
        }
    }

    public static void main(String[] args) {
        // 构造样例树：
        //       1
        //      / \
        //     2   3
        //    / \   \
        //   4   5   6
        TreeNode root = new TreeNode(1);
        root.left = new TreeNode(2);
        root.right = new TreeNode(3);
        root.left.left = new TreeNode(4);
        root.left.right = new TreeNode(5);
        root.right.right = new TreeNode(6);

        System.out.print("PreRec: "); preorderRec(root); System.out.println();
        System.out.print("InRec:  "); inorderRec(root); System.out.println();
        System.out.print("PostRec: "); postorderRec(root); System.out.println();

        System.out.print("PreIter: "); preorderIter(root); System.out.println();
        System.out.print("InIter:  "); inorderIter(root); System.out.println();
        System.out.print("PostIter: "); postorderIter(root); System.out.println();
    }
}
```

### 思路说明：

- **递归方法** 利用系统调用栈自动处理节点访问顺序：S

- 前序：根→左→右
- 中序：左→根→右
- 后序：左→右→根

- **非递归方法** 使用显式 `Stack` 模拟递归流程：B

- 前序：访问当前，先入右子后入左子。
- 中序：一路左入栈，访问后右转。
- 后序：先将访问顺序反向入临时栈，再弹出即为左右根顺序。
