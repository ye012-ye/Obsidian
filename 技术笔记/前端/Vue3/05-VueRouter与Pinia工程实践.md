---
title: Vue3 Vue Router 与 Pinia 工程实践
tags:
  - Vue3
  - VueRouter
  - Pinia
  - 状态管理
created: 2026-06-13
up: "[[00-MOC-Vue3从0基础到大神]]"
description: 学习 Vue Router 4 路由配置、路由参数、路由守卫、Pinia store、登录状态和权限菜单。
---

# Vue3 Vue Router 与 Pinia 工程实践

> [!info] 本章抓什么
> Router 解决“URL 对应哪个页面”，Pinia 解决“跨组件共享什么状态”。后台管理、商城、知识库、仪表盘项目基本都离不开这两块。

## 安装

```bash
npm install vue-router pinia
```

注册：

```js
import { createApp } from "vue";
import { createPinia } from "pinia";
import App from "./App.vue";
import router from "./router";

createApp(App).use(createPinia()).use(router).mount("#app");
```

## Vue Router 基础

`src/router/index.js`：

```js
import { createRouter, createWebHistory } from "vue-router";

const routes = [
  {
    path: "/",
    component: () => import("@/views/HomeView.vue"),
  },
  {
    path: "/users/:id",
    component: () => import("@/views/UserDetailView.vue"),
  },
];

export default createRouter({
  history: createWebHistory(),
  routes,
});
```

页面出口：

```vue
<template>
  <RouterView />
</template>
```

跳转：

```vue
<RouterLink to="/users/1">用户详情</RouterLink>
```

编程式跳转：

```js
import { useRouter } from "vue-router";

const router = useRouter();
router.push("/users/1");
```

## 路由参数

```js
import { useRoute } from "vue-router";

const route = useRoute();
const userId = route.params.id;
const keyword = route.query.keyword;
```

> [!warning] route 是响应式对象
> 同一个组件复用时，路由参数变化不一定重新创建组件。需要监听参数变化时用 `watch(() => route.params.id, ...)`。

## 路由元信息与守卫

```js
const routes = [
  {
    path: "/admin",
    component: () => import("@/views/AdminView.vue"),
    meta: {
      requiresAuth: true,
      roles: ["admin"],
    },
  },
];
```

全局守卫：

```js
router.beforeEach((to) => {
  const userStore = useUserStore();

  if (to.meta.requiresAuth && !userStore.isLogin) {
    return {
      path: "/login",
      query: { redirect: to.fullPath },
    };
  }

  if (to.meta.roles && !to.meta.roles.includes(userStore.role)) {
    return "/403";
  }
});
```

## Pinia 基础

`src/stores/user.js`：

```js
import { defineStore } from "pinia";
import { computed, ref } from "vue";

export const useUserStore = defineStore("user", () => {
  const token = ref("");
  const profile = ref(null);

  const isLogin = computed(() => Boolean(token.value));
  const role = computed(() => profile.value?.role ?? "guest");

  function setToken(value) {
    token.value = value;
  }

  function setProfile(value) {
    profile.value = value;
  }

  function logout() {
    token.value = "";
    profile.value = null;
  }

  return {
    token,
    profile,
    isLogin,
    role,
    setToken,
    setProfile,
    logout,
  };
});
```

组件使用：

```vue
<script setup>
import { storeToRefs } from "pinia";
import { useUserStore } from "@/stores/user";

const userStore = useUserStore();
const { profile, isLogin } = storeToRefs(userStore);
</script>
```

> [!success] Pinia 推荐保存什么
> 登录用户、token、权限、主题、全局配置、购物车、跨页面筛选条件。纯组件内部状态不要都丢进 Pinia。

## Pinia 持久化思路

简单手写：

```js
watch(
  () => userStore.token,
  (token) => {
    localStorage.setItem("token", token);
  },
  { immediate: true }
);
```

初始化：

```js
const token = ref(localStorage.getItem("token") ?? "");
```

更复杂项目可使用 Pinia 插件，但要先理解原理。

## 菜单与权限

路由表可以带权限信息：

```js
export const menuRoutes = [
  {
    path: "/dashboard",
    title: "首页",
    roles: ["admin", "user"],
  },
  {
    path: "/system",
    title: "系统管理",
    roles: ["admin"],
  },
];
```

过滤：

```js
const visibleMenus = computed(() =>
  menuRoutes.filter((item) => item.roles.includes(userStore.role))
);
```

## 本章练习

1. 配置首页、登录页、用户详情页。
2. 用路由参数读取用户 id。
3. 写登录守卫，未登录跳转登录页。
4. 用 Pinia 保存用户信息和 token。
5. 根据角色过滤菜单。

## 官方资料入口

- Vue Router Guide: https://router.vuejs.org/guide/
- Pinia Core Concepts: https://pinia.vuejs.org/core-concepts/
- Vue State Management: https://vuejs.org/guide/scaling-up/state-management

## 一句话总结

> Router 管页面位置，Pinia 管共享状态，权限系统就是二者和后端登录信息的组合。
