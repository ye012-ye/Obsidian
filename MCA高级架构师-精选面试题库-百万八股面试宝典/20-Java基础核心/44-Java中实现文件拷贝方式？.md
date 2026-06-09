在Java中，文件拷贝的方式多种多样，每种方式适用于不同的场景。以下是五种常见的文件拷贝方式：M

### 1. 传统字节流拷贝（`FileInputStream` + `FileOutputStream`）

```java
public static void main(String[] args) throws IOException {
    try (InputStream is = new FileInputStream("source.txt");
         OutputStream os = new FileOutputStream("target.txt")) {
        byte[] buffer = new byte[1024];
        int length;
        while ((length = is.read(buffer)) > 0) {
            os.write(buffer, 0, length);
        }
    }
}
```

- **特点**：基础方法，直接逐字节或缓冲区读写。
- **效率**：最低，适合小文件（<10MB）。

### 2. 缓冲流优化拷贝（`BufferedInputStream` + `BufferedOutputStream`）

```java
public static void main(String[] args) throws IOException {
    try (BufferedInputStream bis = new BufferedInputStream(new FileInputStream("source.txt"));
         BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream("target.txt"))) {
        byte[] buffer = new byte[8192]; // 缓冲区越大，性能越好
        int len;
        while ((len = bis.read(buffer)) != -1) {
            bos.write(buffer, 0, len);
        }
    }
}
```

- **特点**：通过缓冲区减少I/O操作的次数。
- **效率**：比传统字节流提升 2~5 倍，适用于中等文件。

### 3. NIO `Files.copy` 方法（Java 7+）

```java
public static void main(String[] args) throws IOException {
    Path source = Paths.get("source.txt");
    Path target = Paths.get("target.txt");
    Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
}
```

- **特点**：使用NIO的`Files.copy`方法，底层自动优化。
- **效率**：接近最高效，适合大多数场景。S

### 4. NIO `FileChannel` 通道拷贝

```java
public static void main(String[] args) throws IOException {
    try (FileChannel sourceChannel = new FileInputStream("source.txt").getChannel();
         FileChannel targetChannel = new FileOutputStream("target.txt").getChannel()) {
        sourceChannel.transferTo(0, sourceChannel.size(), targetChannel);
    }
}
```

- **特点**：利用`FileChannel`直接传输数据。
- **效率**：性能最佳，适合大文件（>100MB），支持零拷贝技术。

### 5. 内存映射文件拷贝（`MappedByteBuffer`）

```java
public static void main(String[] args) throws IOException {
    try (RandomAccessFile sourceFile = new RandomAccessFile("source.txt", "r");
         RandomAccessFile targetFile = new RandomAccessFile("target.txt", "rw")) {
        FileChannel sourceChannel = sourceFile.getChannel();
        MappedByteBuffer buffer = sourceChannel.map(FileChannel.MapMode.READ_ONLY, 0, sourceChannel.size());
        targetFile.getChannel().write(buffer);
    }
}
```

- **特点**：将文件映射到内存直接操作。
- **效率**：适合超大文件（>1GB），但实现较为复杂，需谨慎处理内存。B
