快速排序（QuickSort）是一种高效的**分治排序**算法。它通过选取基准（pivot）元素进行分区，将数组分为“小于 pivot”和“大于 pivot”两部分，然后递归地对这两部分排序。

M

#### 完整 代码示例

```java
public class QuickSortExample {

    public static void quickSort(int[] arr, int low, int high) {
        if (low < high) { 
                          int pi = partition(arr, low, high);
                          quickSort(arr, low, pi - 1);
                          quickSort(arr, pi + 1, high); 
                        }
    }

    private static int partition(int[] arr, int low, int high) {
        int pivot = arr[high];
        int i = low - 1;
        for (int j = low; j < high; j++) {
            if (arr[j] <= pivot) {
                i++;
                int tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp; 
            }
        }
        int tmp = arr[i + 1];
        arr[i + 1] = arr[high];
        arr[high] = tmp;
        return i + 1;
    }

    public static void main(String[] args) {
        int[] a = {10, 7, 8, 9, 1, 5};
        quickSort(a, 0, a.length - 1);
        for (int v : a) System.out.print(v + " ");
    }
}
```

S

### 核心逻辑

- **选择基准**：常用方式是选取数组最后或随机元素，目的是使分区尽量平衡。
- **分区过程**：一次遍历，将小于等于 pivot 的元素交换到前面，最后将 pivot 放置其正确位置。
- **递归排序**：对分区后的左右子数组重复上述步骤，直至 `low < high` 不满足。

B

### 复杂度分析

- **平均/最佳时间复杂度**：O(n log n)。当每次分区较平衡时，总比较成本≈ n × log n。
- **最坏时间复杂度**：O(n²)。若每次选取的 pivot 导致高度不平衡，比如已排好序或逆序数组。
- **空间复杂度**：平均 O(log n)，取决于递归栈深度；最坏 O(n) 当递归退化为链式。
