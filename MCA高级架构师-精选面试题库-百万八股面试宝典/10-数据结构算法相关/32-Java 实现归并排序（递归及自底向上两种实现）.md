归并排序是一种稳定的**分治算法**，它通过将数组分解、排序后再合并来实现高效排序。

M

#### ​1. 递归（自顶向下）

```java
public class MergeSortRecursive {
    public static void mergeSortRec(int[] arr, int left, int right) {
        if (left >= right) return; 
        int mid = left + (right - left) / 2;
        mergeSortRec(arr, left, mid);
        mergeSortRec(arr, mid + 1, right);
        merge(arr, left, mid, right); 
    }

    private static void merge(int[] arr, int left, int mid, int right) {
        int[] tmp = new int[right - left + 1];
        int i = left, j = mid + 1, k = 0;
        while (i <= mid && j <= right) {
            tmp[k++] = (arr[i] <= arr[j]) ? arr[i++] : arr[j++];
        }
        while (i <= mid) tmp[k++] = arr[i++];
        while (j <= right) tmp[k++] = arr[j++];
        System.arraycopy(tmp, 0, arr, left, tmp.length); 
    }

    public static void main(String[] args) {
        int[] arr = {12, 11, 13, 5, 6, 7};
        mergeSortRec(arr, 0, arr.length - 1);
        for (int v : arr) System.out.print(v + " ");
    }
}
```

**思路分析：**  
从整体出发，递归拆分数组为左右两部分，直到长度为1。合并阶段将两个有序子数组通过辅助数组 临时合并。该方式典型地体现“分治（Divide & Conquer）”策略。

S

#### 2. 自底向上（迭代）

```java
public class MergeSortIterative {

    public static void mergeSortIter(int[] arr) {
        int n = arr.length;
        for (int sz = 1; sz < n; sz <<= 1) {
            for (int left = 0; left + sz < n; left += sz << 1) {
                int mid = left + sz - 1;
                int right = Math.min(left + (sz << 1) - 1, n - 1);
                MergeSortRecursive.merge(arr, left, mid, right); 
            }
        }
    }

    public static void main(String[] args) {
        int[] arr = {12, 11, 13, 5, 6, 7};
        mergeSortIter(arr);
        for (int v : arr) System.out.print(v + " ");
    }
}
```

**思路分析：**  
该方法由小规模（长度为1）的子数组逐步合并成更长子数组。每轮合并长度加倍（1,2,4…），直至整个数组有序。通过迭代方式替代递归，适用于不希望使用大量调用栈场景。

B
