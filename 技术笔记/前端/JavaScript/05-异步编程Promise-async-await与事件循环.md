---
title: JavaScript 异步编程、Promise、async await 与事件循环
tags:
  - JavaScript
  - Promise
  - async-await
  - 事件循环
created: 2026-06-13
up: "[[00-MOC-JavaScript从0基础到大神]]"
description: 理解异步任务、Promise 状态、async/await、错误处理、并发控制、fetch 请求和事件循环。
---

# JavaScript 异步编程、Promise、async await 与事件循环

> [!info] 本章抓什么
> 前端几乎所有真实业务都有异步：接口请求、定时器、文件读取、动画、用户事件。异步学不好，页面就会出现加载顺序错乱、重复请求、状态覆盖、错误吞掉等问题。

## 同步与异步

同步代码按顺序执行：

```js
console.log("A");
console.log("B");
console.log("C");
```

异步代码会把回调留到以后执行：

```js
console.log("A");

setTimeout(() => {
  console.log("B");
}, 0);

console.log("C");
```

输出通常是 `A C B`。

## Promise 三种状态

Promise 表示一个未来完成的结果。

| 状态 | 含义 |
|---|---|
| `pending` | 进行中 |
| `fulfilled` | 成功 |
| `rejected` | 失败 |

```js
const promise = new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve("成功");
  }, 1000);
});

promise
  .then((value) => {
    console.log(value);
  })
  .catch((error) => {
    console.error(error);
  })
  .finally(() => {
    console.log("结束");
  });
```

> [!warning] Promise 一旦 settled 就不能再改状态
> `resolve` 或 `reject` 之后，后续再调用不会改变结果。

## async/await

`async` 函数总是返回 Promise。`await` 会等待 Promise settled。

```js
async function loadUser() {
  const response = await fetch("/api/user");
  if (!response.ok) {
    throw new Error("请求失败");
  }
  return await response.json();
}
```

错误处理：

```js
async function main() {
  try {
    const user = await loadUser();
    console.log(user);
  } catch (error) {
    console.error("加载用户失败", error);
  }
}
```

## fetch 请求模板

```js
async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    ...options,
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return await response.json();
}

const users = await request("/api/users");
```

> [!danger] fetch 只有网络层失败才自动 reject
> HTTP 404、500 不会自动进入 `catch`，需要自己检查 `response.ok`。

## 并发与串行

串行：后一个依赖前一个。

```js
const user = await request("/api/user");
const orders = await request(`/api/users/${user.id}/orders`);
```

并发：彼此不依赖。

```js
const [user, config, messages] = await Promise.all([
  request("/api/user"),
  request("/api/config"),
  request("/api/messages"),
]);
```

容错并发：

```js
const results = await Promise.allSettled([
  request("/api/a"),
  request("/api/b"),
]);
```

## 竞态问题

用户快速搜索时，后发请求可能先回来，旧结果覆盖新结果。

```js
let requestId = 0;

async function search(keyword) {
  const currentId = ++requestId;
  const result = await request(`/api/search?q=${encodeURIComponent(keyword)}`);

  if (currentId !== requestId) {
    return;
  }

  render(result);
}
```

也可以使用 `AbortController` 取消旧请求：

```js
let controller;

async function search(keyword) {
  controller?.abort();
  controller = new AbortController();

  const response = await fetch(`/api/search?q=${encodeURIComponent(keyword)}`, {
    signal: controller.signal,
  });

  return await response.json();
}
```

## 事件循环：宏任务与微任务

简化理解：

1. 同步代码先执行。
2. 当前同步代码结束后，先清空微任务队列。
3. 再执行一个宏任务。
4. 然后继续微任务、渲染、下一个宏任务。

常见分类：

| 类型 | 示例 |
|---|---|
| 同步任务 | 普通 JS 调用 |
| 微任务 | Promise `.then`、`queueMicrotask` |
| 宏任务 | `setTimeout`、事件回调、I/O |

```js
console.log("start");

setTimeout(() => console.log("timeout"), 0);

Promise.resolve().then(() => console.log("promise"));

console.log("end");
```

输出：

```text
start
end
promise
timeout
```

> [!warning] 不要把事件循环背成死题
> 面试要讲清“同步先走、微任务优先于下一个宏任务”，项目里要能识别：为什么 loading 先/后消失，为什么状态更新顺序错了，为什么 Promise 报错没 catch。

## 本章练习

1. 写一个 `sleep(ms)`。
2. 用 `Promise.all` 并发加载用户、配置、消息。
3. 封装一个检查 `response.ok` 的请求函数。
4. 解释 `setTimeout` 和 Promise 的输出顺序。
5. 模拟搜索接口竞态，并用 requestId 或 AbortController 修复。

## 官方资料入口

- Using promises: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises
- async function: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function
- JavaScript execution model: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Execution_model
- Fetch API: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API

## 一句话总结

> 异步的核心不是“等一下”，而是管理执行顺序、错误传播和并发关系。
