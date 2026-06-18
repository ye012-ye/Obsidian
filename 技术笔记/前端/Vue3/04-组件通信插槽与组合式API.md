---
title: Vue3 组件通信、插槽与组合式 API
tags:
  - Vue3
  - 组件通信
  - 插槽
  - CompositionAPI
created: 2026-06-13
up: "[[00-MOC-Vue3从0基础到大神]]"
description: 掌握 props、emit、v-model、provide/inject、slot、scoped slot 和 composable 复用逻辑。
---

# Vue3 组件通信、插槽与组合式 API

> [!info] 本章抓什么
> 组件化的难点不是“拆文件”，而是拆职责、传数据、复用逻辑。组件通信决定数据怎么流动，插槽决定结构怎么扩展，组合式 API 决定逻辑怎么复用。

## 通信方式总览

| 方式 | 适合场景 |
|---|---|
| props | 父组件传数据给子组件 |
| emit | 子组件通知父组件 |
| v-model | 父子双向绑定表单类值 |
| provide/inject | 跨层级传依赖 |
| Pinia | 跨页面、跨模块共享状态 |
| slot | 父组件决定子组件某块内容 |

## props + emit

子组件：

```vue
<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["remove"]);
</script>

<template>
  <article>
    <span>{{ title }}</span>
    <button @click="emit('remove')">删除</button>
  </article>
</template>
```

父组件：

```vue
<TodoItem
  v-for="todo in todos"
  :key="todo.id"
  :title="todo.title"
  @remove="removeTodo(todo.id)"
/>
```

## v-model

子组件 `BaseInput.vue`：

```vue
<script setup>
defineProps({
  modelValue: String,
});

const emit = defineEmits(["update:modelValue"]);
</script>

<template>
  <input
    :value="modelValue"
    @input="emit('update:modelValue', $event.target.value)"
  />
</template>
```

父组件：

```vue
<BaseInput v-model="keyword" />
```

## provide / inject

适合主题、配置、表单上下文等跨层级依赖。

上层组件：

```js
import { provide, ref } from "vue";

const theme = ref("light");
provide("theme", theme);
```

后代组件：

```js
import { inject } from "vue";

const theme = inject("theme");
```

> [!warning] 不要滥用 provide/inject
> 它会让数据来源变隐蔽。普通父子通信用 props/emit，真正跨层级基础设施再用 provide/inject。

## 默认插槽

`BaseCard.vue`：

```vue
<template>
  <section class="card">
    <slot />
  </section>
</template>
```

使用：

```vue
<BaseCard>
  <h3>用户信息</h3>
  <p>这里由父组件决定内容</p>
</BaseCard>
```

## 具名插槽

```vue
<template>
  <section>
    <header><slot name="header" /></header>
    <main><slot /></main>
    <footer><slot name="footer" /></footer>
  </section>
</template>
```

```vue
<BaseLayout>
  <template #header>标题</template>
  <p>主体内容</p>
  <template #footer>底部按钮</template>
</BaseLayout>
```

## 作用域插槽

子组件把数据暴露给父组件决定怎么渲染。

```vue
<template>
  <ul>
    <li v-for="item in items" :key="item.id">
      <slot :item="item">{{ item.name }}</slot>
    </li>
  </ul>
</template>
```

```vue
<DataList :items="users">
  <template #default="{ item }">
    <strong>{{ item.name }}</strong>
    <span>{{ item.role }}</span>
  </template>
</DataList>
```

## 组合式函数 composable

把可复用逻辑抽到 `useXxx` 函数。

```js
// composables/useRequest.js
import { ref } from "vue";

export function useRequest(service) {
  const data = ref(null);
  const loading = ref(false);
  const error = ref(null);

  async function run(...args) {
    loading.value = true;
    error.value = null;
    try {
      data.value = await service(...args);
    } catch (err) {
      error.value = err;
    } finally {
      loading.value = false;
    }
  }

  return { data, loading, error, run };
}
```

使用：

```vue
<script setup>
import { onMounted } from "vue";
import { useRequest } from "@/composables/useRequest";
import { getUsers } from "@/api/user";

const { data: users, loading, error, run } = useRequest(getUsers);

onMounted(() => {
  run();
});
</script>
```

> [!success] composable 适合抽什么
> 请求状态、分页、搜索、防抖、权限判断、窗口尺寸、主题、表单草稿、WebSocket 连接，都很适合抽成组合式函数。

## 本章练习

1. 封装 `BaseModal`，用插槽传标题、内容、底部按钮。
2. 封装 `BaseInput`，支持 `v-model`。
3. 用 `provide/inject` 传主题色。
4. 抽一个 `usePagination` 管分页状态。
5. 抽一个 `useRequest` 管 loading、error、data。

## 一句话总结

> props/emit 管数据流，slot 管结构扩展，composable 管逻辑复用。
