---
title: JavaScript DOM、事件与浏览器 API
tags:
  - JavaScript
  - DOM
  - 事件
  - 浏览器
created: 2026-06-13
up: "[[00-MOC-JavaScript从0基础到大神]]"
description: 从 DOM 查询、节点更新、事件绑定、事件委托到 localStorage、URL、FormData 等浏览器常用 API。
---

# JavaScript DOM、事件与浏览器 API

> [!info] 本章抓什么
> DOM 是页面结构，事件是用户行为，浏览器 API 是前端和环境交互的能力。即使你以后主要写 Vue3，也要理解框架背后最终仍然在操作 DOM 和监听事件。

## DOM 查询

```html
<h1 id="title">Todo</h1>
<ul class="list">
  <li data-id="1">学习 JS</li>
</ul>
```

```js
const title = document.querySelector("#title"); //id
const list = document.querySelector(".list"); //class
const items = document.querySelectorAll(".list li"); 
```

## 修改内容与属性

```js
title.textContent = "我的任务"; //textContent 覆盖内容
title.classList.add("active"); //class='active'
title.setAttribute("data-page", "todo");
```

常用属性：

| API                           | 作用          |
| ----------------------------- | ----------- |
| `textContent`                 | 设置纯文本       |
| `innerHTML`                   | 设置 HTML     |
| `classList.add/remove/toggle` | 操作 class    |
| `setAttribute/getAttribute`   | 操作属性        |
| `dataset`                     | 读取 `data-*` |

> [!danger] 谨慎使用 innerHTML
> 如果内容来自用户输入或接口返回，直接放进 `innerHTML` 可能造成 XSS。能用 `textContent` 就优先用 `textContent`。

## 创建和插入节点

```js
const li = document.createElement("li"); //创建元素
li.textContent = "学习 DOM";
li.dataset.id = "2";

list.append(li);
```

批量渲染可以用字符串，但要注意安全：

```js
const todos = [
  { id: 1, title: "学习 JS" },
  { id: 2, title: "学习 Vue3" },
];

list.innerHTML = todos
  .map((todo) => `<li data-id="${todo.id}">${todo.title}</li>`)
  .join("");
```

## 事件绑定

```js
const button = document.querySelector("#add"); id='add'

button.addEventListener("click", (event) => {
  console.log("点击了按钮", event);
});
```

常见事件：

| 事件 | 说明 |
|---|---|
| `click` | 点击 |
| `input` | 输入实时变化 |
| `change` | 值提交变化 |
| `submit` | 表单提交 |
| `keydown` | 键盘按下 |
| `scroll` | 滚动 |

## 事件冒泡与事件委托

事件会从目标元素向父元素冒泡。

```js
list.addEventListener("click", (event) => {
  const item = event.target.closest("li");
  if (!item) return;

  console.log("点击任务", item.dataset.id);
});
```

> [!success] 事件委托适合列表
> 列表项是动态创建的，不要给每个 `li` 单独绑定事件。把事件绑定到父容器，通过 `event.target` 判断点击的是谁。

## 阻止默认行为和冒泡

```js
const form = document.querySelector("form");

form.addEventListener("submit", (event) => {
  event.preventDefault();
  console.log("自己处理提交");
});
```

```js
button.addEventListener("click", (event) => {
  event.stopPropagation();
});
```

## localStorage //本地储存

```js
const todos = [{ id: 1, title: "学习 JS" }];

localStorage.setItem("todos", JSON.stringify(todos));

const saved = JSON.parse(localStorage.getItem("todos") ?? "[]");
```

> [!warning] localStorage 只适合少量非敏感数据
> 不要把 token、密码、隐私信息随便放进 `localStorage`。安全要求高的项目要结合 HttpOnly Cookie、后端会话和权限策略。

## URLSearchParams  URL搜索器

```js
const params = new URLSearchParams(location.search);
const page = Number(params.get("page") ?? 1);
```

生成查询字符串：

```js
const query = new URLSearchParams({
  keyword: "vue",
  page: "1",
}).toString();
```

## FormData

```js
form.addEventListener("submit", (event) => {
  event.preventDefault();

  const formData = new FormData(form);
  const payload = Object.fromEntries(formData.entries());

  console.log(payload);
});
```

## 最小 Todo 示例

```html
<form id="todo-form">
  <input name="title" placeholder="输入任务" />
  <button>添加</button>
</form>
<ul id="todo-list"></ul>
```

```js
const form = document.querySelector("#todo-form");
const list = document.querySelector("#todo-list");
let todos = JSON.parse(localStorage.getItem("todos") ?? "[]");

function save() {
  localStorage.setItem("todos", JSON.stringify(todos));
}

function render() {
  list.innerHTML = todos
    .map((todo) => `<li data-id="${todo.id}">${todo.title}</li>`)
    .join("");
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const formData = new FormData(form);
  const title = String(formData.get("title") ?? "").trim();
  if (!title) return;

  todos = [...todos, { id: Date.now(), title }];
  save();
  render();
  form.reset();
});

list.addEventListener("click", (event) => {
  const item = event.target.closest("li");
  if (!item) return;

  const id = Number(item.dataset.id);
  todos = todos.filter((todo) => todo.id !== id);
  save();
  render();
});

render();
```

## 本章练习

1. 做一个计数器按钮。
2. 做一个 Todo 新增、删除、保存。
3. 用事件委托处理动态列表点击。
4. 用 URLSearchParams 读取地址栏参数。

## 一句话总结

> DOM 负责页面结构，事件负责用户行为，浏览器 API 负责和运行环境交互。
