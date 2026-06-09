HDFS中，数据被切分成Block，切分数据过程中HDFS并不会感知数据文件内容（如换行符），有可能导致一行数据被切分到两个Block中。

当 MapReduce 任务运行时，Hadoop采用LineRecordReader机制（一行行读取）来保证每个 Mapper读取的行是完整的，每个MapTask处理对应的InputSplit，具体策略要点如下：

- 每个Split在读取时（除最后一个Split之外），每个Split都会额外多读取下个Split的一行数据，确保跨Split的行能够完整交由上一个Split的MapTask处理。
- 每个Split在读取时（除第一个Split分片），跳过该Split的第一行，从下一行开始读取数据。

所以，在MapReduce中，通过LineRecordReader采用“让出当前 Split 的第一行 + 额外读取下一行”的策略，确保行数据不会被错误拆分到多个 MapTask，从而保证文本的完整性。
