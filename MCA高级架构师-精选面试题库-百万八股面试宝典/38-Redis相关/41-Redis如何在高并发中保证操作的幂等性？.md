Redis 可以帮助实现高并发场景下的幂等性，以下是几种常用且高效的方式：

M

## 1. 使用 **全局唯一的 幂等 Key + 原子删除**

客户端在每次请求时生成一个唯一的 `idempotency_key`（如 UUID），并在 Redis 中以该 key 做一次原子删除操作：

```plain
DEL idempotency:{key}  → 返回 1 或 0
```

- 如果返回 `1`，表示这是第一次使用该 key，执行核心业务。
- 如果返回 `0`，说明请求重复，直接返回幂等结果，不重复执行业务。

这种方式利用 Redis 原子命令保证“只处理一次”，简单高效。

## 2. 幂等 Token + Lua 脚本

为了实现“检查 + 删除”原子操作，可使用 Lua 脚本：

```lua
-- KEYS[1] 为 key，ARGV[1] 为唯一 token 值
if redis.call("get", KEYS[1]) == ARGV[1] then
  redis.call("del", KEYS[1])
  return 1
else
  return 0
end
```

- 返回 `1` 表示幂等 key 确认有效，执行业务；返回 `0` 表示无效/已使用，跳过。

这种方式兼具验证和删除的原子性，确保并发情况下不漏删或重复处理。

## 3. **WATCH + 乐观锁模式**

借助 Redis 的 `WATCH` 实现乐观并发控制：

1. `WATCH key` 监听幂等 key；
2. `MULTI` 开启事务；
3. 删除 key（`DEL key`），并写入业务结果；
4. `EXEC` 提交事务，仅当 key 未被其他客户端修改时生效。

这种方式适合同步执行场景，防止并发冲突。

## 4. **分布式锁 + Token 校验**

如果业务流程较复杂，可以先获取分布式锁（如 SET NX PX + token），然后检查幂等 key 来保证只执行一次：

1. 利用 `SET lockKey token NX PX timeout` 获取锁；
2. 检查 `idempotency_key` 是否存在；
3. 如果不存在，则执行业务，并写入结果、删除幂等 key；
4. 最后用 Lua 验证 `token` 再释放锁。

这种方式结合了锁机制和 Token 验证，适用于复杂并发场景。

## 5. **Token 存储 + TTL**

在请求发起时，将幂等 Token 存入 Redis 并设置短 TTL（如 5 分钟）：

```plain
SET idempotency:{key} value NX EX 300
```

- 首次执行成功；后续重复请求该 key 已存在，直接判重，快速返回。
- TTL 可防止 Token 永久占用资源，同时确保一定时间内重复请求可识别。
