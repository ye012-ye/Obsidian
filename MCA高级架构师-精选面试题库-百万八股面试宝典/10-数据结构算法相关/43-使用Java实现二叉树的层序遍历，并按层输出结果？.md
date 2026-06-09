可以通过广度优先搜索（BFS）方式处理二叉树，使用队列确保从上到下、从左到右逐层访问节点。以下是思路说明与代码实现：

#### 实现思路

1. 如果根节点为空，直接返回空结果列表。
2. 使用 `Queue<TreeNode>` 存储当前层节点。先将根节点加入队列。S
3. 在每一层循环中，记录当前层的节点数 `size`，然后依次从队列中取出 `size` 个节点，收集它们的值并将子节点（如果不为空）入队。B
4. 每层处理完后，将这一层的结果添加至最终返回列表中。
5. 循环直到队列为空。最终返回包含所有层节点值的嵌套列表结构。M

#### 代码示例

```java
class TreeNode {
    int val;
    TreeNode left, right;
    TreeNode(int v) { val = v; left = right = null; }
}

public class Solution {
    public static List<List<Integer>> levelOrder(TreeNode root) {
        List<List<Integer>> res = new ArrayList<>();
        if (root == null) return res;

        Queue<TreeNode> q = new LinkedList<>();
        q.add(root);

        while (!q.isEmpty()) {
            int size = q.size();
            List<Integer> layer = new ArrayList<>();

            for (int i = 0; i < size; i++) {
                TreeNode node = q.poll();
                layer.add(node.val);
                if (node.left != null) q.add(node.left);
                if (node.right != null) q.add(node.right);
            }

            res.add(layer);
        }
        return res;
    }
}
```

#### 复杂度分析

- **时间复杂度** O(n)：每个节点只访问一次。
- **空间复杂度** O(n)：队列在最坏情况下（完全二叉树最后一层）可能存放约 n/2 个节点。
