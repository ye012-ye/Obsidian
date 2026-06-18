---
title: JavaScript 函数、作用域、闭包与 this
tags:
  - JavaScript
  - 函数
  - 闭包
  - this
created: 2026-06-13
up: "[[00-MOC-JavaScript从0基础到大神]]"
description: 掌握函数声明、箭头函数、作用域链、闭包、this 绑定规则和项目中常见陷阱。
---

# JavaScript 函数、作用域、闭包与 this

> [!info] 本章抓什么
> 函数是 JS 的核心。闭包、回调、事件、Promise、Vue 组合式 API，本质都离不开函数。学本章时要盯住两个问题：变量从哪里找，`this` 到底是谁。

## 函数声明与函数表达式

```js
function add(a, b) {
  return a + b;
}

const multiply = function (a, b) {
  return a * b;
};

const divide = (a, b) => a / b;
```

| 写法 | 特点 |
|---|---|
| 函数声明 | 会被提升，适合公共工具函数 |
| 函数表达式 | 赋值给变量，适合按需传递 |
| 箭头函数 | 写法短，不绑定自己的 `this` |

## 参数默认值与解构参数

```js
function createUser({ name, age = 18, role = "user" }) {
  return { name, age, role };
}

const user = createUser({ name: "小明" });
```

项目中函数参数超过 3 个时，优先考虑对象参数，调用方更清楚。

## 作用域链

```js
const globalName = "全局";

function outer() {
  const outerName = "外层";

  function inner() {
    const innerName = "内层";
    console.log(globalName, outerName, innerName);
  }

  inner();
}
```

变量查找顺序：当前作用域 -> 外层作用域 -> 再外层 -> 全局。

> [!warning] 块级作用域
> `let` 和 `const` 有块级作用域，`var` 没有块级作用域。循环、条件块里尤其要注意。

```js
if (true) {
  let a = 1;
  var b = 2;
}

// console.log(a); // ReferenceError
console.log(b); // 2
```

## 闭包

闭包就是：函数能记住并访问它定义时所在的词法作用域。

```js
function createCounter() {
  let count = 0;

  return function increment() {
    count += 1;
    return count;
  };
}

const counter = createCounter();
console.log(counter()); // 1
console.log(counter()); // 2
```

闭包的常见用途：

1. 保存私有状态。
2. 创建函数工厂。
3. 防抖、节流。
4. 缓存计算结果。
5. 在异步回调里保留上下文。

防抖示例：

```js
function debounce(fn, delay = 300) {
  let timer = null;

  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}
```

> [!danger] 闭包不是越多越好
> 闭包会延长变量生命周期。如果闭包里引用了大型对象、DOM 节点、定时器，又没有清理，可能造成内存泄漏。

## this 的四条常见规则

`this` 取决于函数调用方式，不取决于函数写在哪里。

### 默认调用

```js
function show() {
  console.log(this);
}

show(); // 非严格模式下通常是 window，严格模式下是 undefined
```

### 对象方法调用

```js
const user = {
  name: "小明",
  say() {
    console.log(this.name);
  },
};

user.say(); // 小明
```

### 显式绑定

```js
function say() {
  console.log(this.name);
}

say.call({ name: "张三" });
say.apply({ name: "李四" });

const boundSay = say.bind({ name: "王五" });
boundSay();
```

### new 调用

```js
function User(name) {
  this.name = name;
}

const user = new User("小明");
console.log(user.name);
```

## 箭头函数的 this

箭头函数没有自己的 `this`，它会捕获外层 `this`。

```js
const user = {
  name: "小明",
  sayLater() {
    setTimeout(() => {
      console.log(this.name);
    }, 1000);
  },
};

user.sayLater();
```

> [!warning] 不要把对象方法默认写成箭头函数
> 对象方法如果需要访问对象自身，优先用普通方法。箭头函数常用于回调，而不是对象方法。

## 面试表达模板

闭包可以这样讲：

> 闭包是函数和它定义时词法环境的组合。即使外层函数执行完，内部函数仍然可以访问外层变量。它常用于保存私有状态、函数工厂、防抖节流，但如果长期持有大对象或 DOM 引用，也可能导致内存泄漏。

this 可以这样讲：

> `this` 由调用方式决定。普通函数看谁调用，对象方法指向调用对象，`call/apply/bind` 可以显式指定，构造函数里指向新对象。箭头函数没有自己的 `this`，会捕获外层作用域的 `this`。

## 本章练习

1. 写一个 `createCounter(start)`，每次调用加 1。
2. 写一个 `once(fn)`，保证函数只执行一次。
3. 用 `call` 实现借用数组方法。
4. 比较普通函数和箭头函数在对象方法里的 `this`。

## 一句话总结

> 闭包解决“函数记住什么”，this 解决“函数被谁调用”。
