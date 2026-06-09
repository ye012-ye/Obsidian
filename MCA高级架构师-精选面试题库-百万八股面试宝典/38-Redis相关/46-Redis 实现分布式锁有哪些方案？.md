下面六种方式从基础到高级，层层递进，配合原子性、容错性及集群环境，适合不同场景的分布式锁实现。

### 1. SETNX + EXPIRE

最基本方式：通过 `SETNX` 获取锁，再用 `EXPIRE` 设置 TTL。优点是易实现，但由于两条命令非原子，若中间宕机无法自动释放锁，可能导致死锁。

### 2. SETNX + 内嵌过期时间

在 value 中保存“锁失效时间戳”，加锁失败后检测是否过期并尝试抢占。这种方式解决了简单 SETNX 的死锁问题，但需要客户端时间同步和小心并发覆盖。

### 3. Lua 脚本原子操作

将 SETNX + EXPIRE 封装在 Lua 脚本中执行，实现原子加锁。例如：

```lua
if redis.call('setnx',KEYS[1],ARGV[1])==1 then
  redis.call('expire',KEYS[1],ARGV[2]) return 1
else return 0 end
```

该方法避免了前两种的竞态条件、但仍缺 userToken，因此释放仍需谨慎。

### 4. 使用 `SET ... NX PX`

使用 Redis 的增强命令：

```vbnet
SET key value NX PX ttl
```

支持加锁时的一步设置过期时间。为避免误删他人锁，释放必须先校验 value，再通过 Lua 脚本删除。该方案适合单节点环境，需加 watch-dog 或适当 TTL。

### 5. Redisson + 看门狗（Watchdog）机制

Redisson 封装了上面原子操作并引入“watchdog”后台线程，自动续期锁防止临界区运行期间锁过期释放，从而保证锁完整性与稳定性。适合 JVM 生态使用。

### 6. Redlock 多 master 算法

针对 Redis 单主节点异步复制风险的问题，引入多个独立 Redis 实例，客户端依次尝试在多数节点加锁（quorum），确保在大多数上获得锁并在 TTL 内完成业务，保证强一致性与容错能力。释放时也需在所有实例执行相应 Lua 脚本。适合跨节点、容灾需求高的场景。

**​****对比：**

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **方案** | **原子性** | **可自动续期** | **多节点容错** | **适用场景** |
| SETNX + EXPIRE | 否 | 否 | 否 | 不推荐 |
| SETNX + timestamp | 否 | 否 | 否 | 简易业务 |
| Lua 原子脚本 | 是 | 否 | 否 | 单节点推荐 |
| `SET NX PX` | 是 | 否 | 否 | 单节点推荐 |
| Redisson | 是 | 是 | 否 | JVM 稳健开发 |
| Redlock | 是 | 否（自 TTL） | 是 | 多节点、高可用需求 |
