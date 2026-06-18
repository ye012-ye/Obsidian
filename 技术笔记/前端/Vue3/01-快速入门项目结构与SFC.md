---
title: Vue3 快速入门、项目结构与 SFC
tags:
  - Vue3
  - Vite
  - SFC
created: 2026-06-13
up: "[[00-MOC-Vue3从0基础到大神]]"
description: 从创建 Vue3 项目开始，理解 Vite、目录结构、main.js、App.vue 和单文件组件。
---

# Vue3 快速入门、项目结构与 SFC

> [!info] 本章抓什么
> 先把 Vue3 项目跑起来，再认识每个文件负责什么。你要建立一个心智模型：`main.js` 挂载应用，`App.vue` 是根组件，其他 `.vue` 文件是页面和组件。

## 创建项目

官方推荐方式：

```bash
npm create vue@latest
```

也可以用 Vite 模板：

```bash
npm create vite@latest my-vue-app -- --template vue
cd my-vue-app
npm install
npm run dev
```

> [!warning] Node 版本
> Vue 官方快速开始文档会提示 Node.js 版本要求。实际开发中先用 `node -v` 检查本机版本，再看项目 `package.json` 和锁文件要求，团队项目不要私自乱升主版本。

## 常见目录结构

```text
my-vue-app/
  public/
  src/
    assets/
    components/
    App.vue
    main.js
  index.html
  package.json
  vite.config.js
```

| 文件/目录 | 作用 |
|---|---|
| `index.html` | 页面入口，包含根节点 |
| `src/main.js` | 创建 Vue 应用并挂载 |
| `src/App.vue` | 根组件 |
| `src/components` | 复用组件 |
| `src/assets` | 图片、样式等静态资源 |
| `vite.config.js` | Vite 配置 |

## main.js

```js
import { createApp } from "vue";
import App from "./App.vue";

createApp(App).mount("#app");
```

含义：

1. 从 Vue 导入 `createApp`。
2. 导入根组件 `App.vue`。
3. 创建应用实例。
4. 挂载到 `#app`。

## 单文件组件 SFC

`.vue` 文件通常包含三块：

```vue
<script setup>
import { ref } from "vue";

const count = ref(0);
</script>

<template>
  <button @click="count++">点击 {{ count }}</button>
</template>

<style scoped>
button {
  color: #2563eb;
}
</style>
```

| 区块 | 作用 |
|---|---|
| `<script setup>` | 写组件逻辑 |
| `<template>` | 写组件结构 |
| `<style scoped>` | 写组件样式 |

> [!success] 推荐写法
> 新 Vue3 项目优先用 `<script setup>`。它是 SFC 里使用 Composition API 的推荐语法，写法更短，模板里可以直接使用脚本变量。

## 第一个计数器

```vue
<script setup>
import { ref } from "vue";

const count = ref(0);

function increment() {
  count.value += 1;
}
</script>

<template>
  <main>
    <h1>Vue3 计数器</h1>
    <button @click="increment">点击 {{ count }}</button>
  </main>
</template>
```

注意：

1. JS 里访问 `ref` 要写 `.value`。
2. 模板里会自动解包，可以直接写 `count`。
3. 点击事件用 `@click`。

## 为什么不要直接操作 DOM

传统 JS：

```js
document.querySelector("#count").textContent = count;
```

Vue3：

```vue
<template>
  <span>{{ count }}</span>
</template>
```

Vue 的理念是：状态变化 -> 框架更新视图。你负责管理数据，不负责手动找 DOM 修改。

> [!danger] 初学最常见错误
> 在 Vue 里频繁 `document.querySelector`，通常说明组件状态设计有问题。除非是接第三方库、获取焦点、测量尺寸等特殊场景，否则优先用响应式状态和模板。

## 本章练习

1. 创建一个 Vue3 项目并启动。
2. 修改 `App.vue`，做一个计数器。
3. 新建 `components/HelloCard.vue` 并在 `App.vue` 中引入。
4. 给组件加 `scoped` 样式，观察是否影响其他组件。

## 一句话总结

> Vue3 项目从 `main.js` 挂载开始，用 `.vue` 单文件组件把逻辑、结构和样式组织在一起。
