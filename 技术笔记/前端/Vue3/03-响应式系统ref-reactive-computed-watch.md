---
title: Vue3 响应式系统：ref、reactive、computed、watch
tags:
  - Vue3
  - 响应式
  - ref
  - reactive
  - computed
  - watch
created: 2026-06-13
up: "[[00-MOC-Vue3从0基础到大神]]"
description: 深入理解 Vue3 响应式数据、派生状态、副作用监听、响应式丢失和推荐写法。
---

# Vue3 响应式系统：ref、reactive、computed、watch

> [!info] 本章抓什么
> Vue3 最核心的能力是响应式：数据变化后，依赖它的视图和计算结果自动更新。你要知道什么时候用 `ref`，什么时候用 `reactive`，什么时候用 `computed`，什么时候用 `watch`。

## ref

`ref` 可以包裹任意值。

```vue
<script setup>
import { ref } from "vue";

const count = ref(0);

function increment() {
  count.value += 1;
}
</script>

<template>
  <button @click="increment">{{ count }}</button>
</template>
```

规则：

1. JS 中访问和修改要写 `.value`。
2. 模板中会自动解包。
3. 基础类型优先用 `ref`。

## reactive

`reactive` 用来创建响应式对象。

```vue
<script setup>
import { reactive } from "vue";

const form = reactive({
  username: "",
  password: "",
});
</script>

<template>
  <input v-model="form.username" />
  <input v-model="form.password" type="password" />
</template>
```

> [!warning] reactive 不要直接解构
> 直接解构会丢失响应式。

```js
const state = reactive({ count: 0 });
const { count } = state; // count 不再是响应式引用
```

需要解构时用 `toRefs`：

```js
import { reactive, toRefs } from "vue";

const state = reactive({ count: 0, name: "Vue" });
const { count, name } = toRefs(state);
```

## computed

`computed` 用于派生状态，有缓存。

```vue
<script setup>
import { computed, ref } from "vue";

const price = ref(100);
const count = ref(2);

const total = computed(() => price.value * count.value);
</script>

<template>
  <p>总价：{{ total }}</p>
</template>
```

适合：

1. 根据已有状态计算新值。
2. 列表过滤、排序、汇总。
3. 表单状态派生。

不适合：

1. 发请求。
2. 修改 DOM。
3. 写复杂副作用。

## watch

`watch` 用于响应状态变化后执行副作用。

```vue
<script setup>
import { ref, watch } from "vue";

const keyword = ref("");

watch(keyword, async (newKeyword, oldKeyword) => {
  if (!newKeyword.trim()) return;
  console.log("搜索", newKeyword, oldKeyword);
});
</script>
```

监听多个值：

```js
watch([page, pageSize], ([newPage, newPageSize]) => {
  loadList(newPage, newPageSize);
});
```

立即执行：

```js
watch(
  keyword,
  () => {
    loadData();
  },
  { immediate: true }
);
```

## watchEffect

`watchEffect` 会自动收集依赖。

```js
watchEffect(() => {
  console.log("当前页", page.value, "关键词", keyword.value);
});
```

| API | 适合场景 |
|---|---|
| `computed` | 计算新值 |
| `watch` | 明确监听某些值并执行副作用 |
| `watchEffect` | 依赖较自然、逻辑较轻的副作用 |

> [!danger] 不要用 watch 代替 computed
> 如果只是从 A 算出 B，用 `computed`。如果变化后要请求接口、写缓存、调用外部 API，再用 `watch`。

## ref vs reactive 怎么选

| 场景 | 推荐 |
|---|---|
| 数字、字符串、布尔值 | `ref` |
| 单个数组 | `ref([])` |
| 表单对象 | `reactive({})` 或 `ref({})` 都可 |
| 需要整体替换对象 | `ref({})` |
| 需要解构返回给模板 | `toRefs` 或多个 `ref` |

个人默认策略：

1. 基础值用 `ref`。
2. 列表用 `ref([])`。
3. 表单可以用 `reactive`。
4. composable 返回值优先返回多个 `ref`，调用方更好解构。

## 响应式丢失常见坑

```js
const props = defineProps({ user: Object });
const { user } = props; // 可能导致响应式追踪问题
```

推荐：

```js
import { toRefs } from "vue";

const props = defineProps({ user: Object });
const { user } = toRefs(props);
```

Pinia 里也常见：

```js
import { storeToRefs } from "pinia";

const userStore = useUserStore();
const { userInfo } = storeToRefs(userStore);
```

## 本章练习

1. 用 `ref` 做计数器。
2. 用 `reactive` 做登录表单。
3. 用 `computed` 计算购物车总价。
4. 用 `watch` 监听关键词变化并请求搜索接口。
5. 故意解构 `reactive`，观察响应式丢失。

## 官方资料入口

- Reactivity Fundamentals: https://vuejs.org/guide/essentials/reactivity-fundamentals.html
- Computed Properties: https://vuejs.org/guide/essentials/computed.html
- Watchers: https://vuejs.org/guide/essentials/watchers

## 一句话总结

> `ref/reactive` 管状态，`computed` 管派生，`watch/watchEffect` 管副作用。
