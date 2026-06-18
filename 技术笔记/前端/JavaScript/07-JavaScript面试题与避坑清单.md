---
title: JavaScript 面试题与避坑清单
tags:
  - JavaScript
  - 面试
  - 避坑
created: 2026-06-13
up: "[[00-MOC-JavaScript从0基础到大神]]"
description: 高频 JavaScript 面试题、答题模板、项目坑点和复习清单。
---

# JavaScript 面试题与避坑清单

> [!info] 本章抓什么
> 面试不是背答案，而是把机制讲成“我知道为什么会出问题，也知道项目里怎么避免”。每个问题都要能落到代码、场景和取舍。

## 高频问题速览

| 问题 | 核心关键词 |
|---|---|
| `let`、`const`、`var` 区别 | 块级作用域、提升、重复声明 |
| `==` 和 `===` | 隐式类型转换 |
| 闭包是什么 | 词法作用域、私有状态、内存泄漏 |
| `this` 指向 | 调用方式、箭头函数、bind |
| 原型链 | 对象属性查找、继承 |
| Promise | 状态、链式调用、错误传播 |
| async/await | Promise 语法糖、try/catch |
| 事件循环 | 同步、微任务、宏任务 |
| 防抖节流 | 高频事件优化 |
| 深拷贝浅拷贝 | 引用类型、嵌套对象 |
| 跨域 | 同源策略、CORS |
| XSS/CSRF | 输入输出安全、Cookie 策略 |

## 变量声明

答题模板：

> `var` 是函数作用域，存在变量提升，可以重复声明；`let` 和 `const` 是块级作用域，有暂时性死区，不能在声明前访问。`const` 不能重新赋值，但对象内部属性仍可修改。现代项目默认优先 `const`，需要重新赋值时用 `let`。

## 闭包

```js
function createCounter() {
  let count = 0;
  return () => ++count;
}
```

答题模板：

> 闭包是函数和其词法环境的组合。内部函数即使在外部函数执行结束后，仍然可以访问外部函数的变量。它常用于私有状态、防抖节流、函数工厂，但如果长期引用大对象或 DOM 节点，可能造成内存泄漏。

## this

答题模板：

> `this` 由调用方式决定。普通函数直接调用时，严格模式下是 `undefined`；对象方法调用时指向调用对象；`call/apply/bind` 可以显式绑定；构造函数里指向新对象；箭头函数没有自己的 `this`，会捕获外层 `this`。

## Promise 输出题

```js
console.log(1);

setTimeout(() => console.log(2), 0);

Promise.resolve().then(() => console.log(3));

console.log(4);
```

输出：

```text
1
4
3
2
```

解释：

1. 同步代码先执行。
2. Promise 回调进入微任务。
3. `setTimeout` 进入宏任务。
4. 当前同步栈清空后先执行微任务，再执行下一个宏任务。

## 防抖与节流

防抖：停止触发一段时间后再执行，适合搜索输入。

```js
function debounce(fn, delay = 300) {
  let timer = null;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), delay);
  };
}
```

节流：固定间隔最多执行一次，适合滚动、拖拽。

```js
function throttle(fn, delay = 300) {
  let lastTime = 0;
  return function (...args) {
    const now = Date.now();
    if (now - lastTime < delay) return;
    lastTime = now;
    fn.apply(this, args);
  };
}
```

## 浅拷贝与深拷贝

```js
const user = { profile: { city: "杭州" } };
const copy = { ...user };
copy.profile.city = "上海";
console.log(user.profile.city); // 上海
```

答题模板：

> 浅拷贝只复制第一层引用，嵌套对象仍然共享。深拷贝会递归复制嵌套结构。简单数据可以用 `structuredClone`，但函数、DOM 节点、特殊对象需要额外处理。项目里更推荐减少深层修改，使用不可变更新和清晰的数据结构。

## 项目避坑清单

> [!danger] 线上高频坑
> - 接口 500 没处理，页面一直 loading。
> - 快速搜索导致旧请求覆盖新请求。
> - 事件重复绑定，点击一次触发多次。
> - `localStorage` 保存对象时忘记 `JSON.stringify`。
> - `Array.map` 里忘记 `return`。
> - `undefined.map` 导致白屏。
> - `innerHTML` 渲染用户输入导致 XSS 风险。
> - 浅拷贝修改嵌套对象，导致原状态被污染。

## 面试复习顺序

1. 变量、类型、等值比较。
2. 函数、闭包、this。
3. 原型、对象、继承。
4. 数组 API、数据处理。
5. Promise、async/await、事件循环。
6. DOM、事件、事件委托。
7. 浏览器缓存、跨域、安全。
8. 工程化、构建、调试、性能。

## 一句话总结

> JS 面试真正考的是：你能不能从语法走到运行机制，再走到项目里的问题处理。
