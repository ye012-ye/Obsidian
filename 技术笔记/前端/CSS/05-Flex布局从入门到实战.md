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

