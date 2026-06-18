---
title: CSS 05 - Flex 布局从入门到实战
tags:
  - 前端
  - CSS
  - Flex
created: 2026-06-18
up: "[[00-MOC-CSS从0基础到大神]]"
description: 掌握 Flex 主轴交叉轴、对齐、换行、伸缩、常见页面布局和实战模板。
---

# CSS 05 - Flex 布局从入门到实战

> [!tip] Flex 的核心
> Flex 是一维布局系统，擅长处理一行或一列里的空间分配、对齐、居中、换行。只要你在想“这几个东西怎么横着排、竖着排、平均分、靠右、居中”，优先想到 Flex。

## 开启 Flex

```css
.toolbar {
  display: flex;
}
```

直接子元素会成为 flex item。

## 主轴和交叉轴

Flex 先确定主轴，再处理交叉轴。

```css
.row {
  display: flex;
  flex-direction: row;
}

.column {
  display: flex;
  flex-direction: column;
}
```

| `flex-direction` | 主轴 |
|---|---|
| `row` | 从左到右 |
| `row-reverse` | 从右到左 |
| `column` | 从上到下 |
| `column-reverse` | 从下到上 |

## Flex 关键字认知

> [!info] Flex 先分清“容器”和“子项”
> 写了 `display: flex` 的元素叫 flex container。它的直接子元素叫 flex item。很多属性只能写在容器上，另一些属性只能写在子项上。

### flex container

Flex 容器。它负责安排直接子元素怎么排。

```css
.toolbar {
  display: flex;
}
```

容器上常写：`flex-direction`、`justify-content`、`align-items`、`flex-wrap`、`gap`。

### flex item

Flex 子项，也就是 Flex 容器的直接子元素。

```html
<div class="toolbar">
  <button>保存</button>
  <button>取消</button>
</div>
```

这里两个 `button` 都是 flex item。子项上常写：`flex`、`flex-grow`、`flex-shrink`、`flex-basis`、`align-self`。

### main axis / cross axis

`main axis` 是主轴，Flex 主要排列方向；`cross axis` 是交叉轴，和主轴垂直。`flex-direction` 改了，主轴和交叉轴也会跟着换。

## 主轴对齐 `justify-content`

```css
.nav {
  display: flex;
  justify-content: space-between;
}
```

常用值：

| 值 | 效果 |
|---|---|
| `flex-start` | 靠主轴起点 |
| `center` | 居中 |
| `flex-end` | 靠主轴终点 |
| `space-between` | 两端贴边，中间均分 |
| `space-around` | 每个元素两侧都有空间 |
| `space-evenly` | 所有间距完全相等 |

关键词认知：`justify-content` 永远管主轴。不要死记“水平居中”，因为当 `flex-direction: column` 时，主轴变成纵向，它就管上下分布。

## 交叉轴对齐 `align-items`

```css
.toolbar {
  display: flex;
  align-items: center;
}
```

常用值：

| 值 | 效果 |
|---|---|
| `stretch` | 默认拉伸 |
| `flex-start` | 靠交叉轴起点 |
| `center` | 交叉轴居中 |
| `flex-end` | 靠交叉轴终点 |
| `baseline` | 基线对齐 |

关键词认知：`align-items` 永远管交叉轴。常见的“图标和文字垂直居中”，通常就是在横向 Flex 容器上写 `align-items: center`。

## 最常用居中

```css
.center {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

> [!success] 记住这个模板
> 单个元素水平垂直居中，Flex 是最稳的基础方案之一。

## 间距 `gap`

```css
.actions {
  display: flex;
  gap: 12px;
}
```

现代项目优先用 `gap`，比给每个子元素写 `margin-right` 更干净。

关键词认知：`gap` 是子项之间的缝，不是容器外面的距离。容器和外部元素的距离仍然用 `margin`。

## 换行 `flex-wrap`

```css
.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
```

标签列表、按钮组、头像组很适合这样写。

## 子项伸缩

### `flex: 1`

```css
.layout {
  display: flex;
}

.sidebar {
  width: 240px;
}

.content {
  flex: 1;
}
```

`content` 会占据剩余空间。

关键词认知：`flex: 1` 最常见的人话解释是“把剩余空间都给我”。后台布局里左侧固定、右侧自适应，经常就是右侧写 `flex: 1`。

### `flex` 完整含义

```css
.item {
  flex: 1 1 0;
}
```

对应：

1. `flex-grow`：剩余空间如何放大。
2. `flex-shrink`：空间不足时如何缩小。
3. `flex-basis`：分配前的基础尺寸。

常用写法：

| 写法 | 含义 |
|---|---|
| `flex: 1` | 占满剩余空间，常用于等分 |
| `flex: none` | 不放大不缩小 |
| `flex: 0 0 240px` | 固定基础宽度 240px |

### `flex-grow`

有剩余空间时，子项是否放大。

```css
.main {
  flex-grow: 1;
}
```

`1` 表示愿意参与瓜分剩余空间。

### `flex-shrink`

空间不够时，子项是否缩小。

```css
.sidebar {
  flex-shrink: 0;
}
```

侧边栏不想被压窄，就常写 `flex-shrink: 0`。

### `flex-basis`

分配空间前的基础尺寸。

```css
.sidebar {
  flex-basis: 240px;
}
```

它不是最终宽度，而是参与 Flex 分配前的起始尺寸。

## 自动推到右侧

```css
.nav {
  display: flex;
  align-items: center;
}

.nav-actions {
  margin-left: auto;
}
```

`margin-left: auto` 会吃掉左侧剩余空间，把元素推到右边。

## 常见布局模板

### 顶部导航

```css
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
  padding: 0 24px;
  border-bottom: 1px solid #d0d7de;
}

.nav-links {
  display: flex;
  gap: 16px;
}
```

### 左侧固定，右侧自适应

```css
.app-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  flex: 0 0 240px;
}

.main {
  flex: 1;
  min-width: 0;
}
```

> [!warning] `min-width: 0` 很重要
> Flex 子项默认 `min-width: auto`，里面有长文本或表格时可能撑爆布局。右侧自适应区域经常要加 `min-width: 0`。

关键词认知：`min-width: 0` 的作用是允许 Flex 子项真的变窄。没有它时，子项可能坚持“我的内容最小也要这么宽”，于是把父容器撑出横向滚动条。

### 卡片等高

```css
.cards {
  display: flex;
  gap: 16px;
}

.card {
  flex: 1;
}
```

## Flex 不适合什么

Flex 是一维布局，如果你同时关心行和列，Grid 更适合。

不适合：

1. 复杂二维网格。
2. 明确的页面区域布局。
3. 多行多列都要严格对齐的卡片墙。

## 本章练习

1. 用 Flex 写一个顶部导航。
2. 用 Flex 写一个左右布局后台页面。
3. 用 Flex 写一个按钮组，按钮之间用 `gap`。
4. 用 `margin-left: auto` 把登录按钮推到右边。
5. 用 `flex-wrap` 写一个标签列表。

## 一句话总结

> Flex 解决一维空间分配：方向、对齐、间距、伸缩、换行；绝大多数常见横排竖排布局都能靠它优雅完成。
