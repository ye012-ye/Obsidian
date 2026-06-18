---
title: CSS 06 - Grid 布局响应式与媒体查询
tags:
  - 前端
  - CSS
  - Grid
  - 响应式
created: 2026-06-18
up: "[[00-MOC-CSS从0基础到大神]]"
description: 掌握 Grid 二维布局、fr、repeat、minmax、auto-fit、媒体查询和移动端适配思路。
---

# CSS 06 - Grid 布局响应式与媒体查询

> [!tip] Grid 的核心
> Grid 是二维布局系统，适合同时处理行和列。页面骨架、仪表盘、卡片网格、图片墙、表单排版，都很适合 Grid。

## 开启 Grid

```css
.grid {
  display: grid;
}
```

直接子元素会成为 grid item。

## 定义列

```css
.cards {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
}
```

`fr` 表示剩余空间份额。`1fr 1fr 1fr` 就是三等分。

## Grid 关键字认知

> [!info] Grid 是“先画格子，再把元素放进格子”
> Flex 更像排队，Grid 更像画表格。你先定义列和行，再让子元素落到对应网格里。

### grid container / grid item

写了 `display: grid` 的元素就是 Grid 容器，它的直接子元素就是 Grid 子项。

### `grid-template-columns`

定义有几列，每列多宽。

```css
.cards {
  grid-template-columns: 240px 1fr;
}
```

人话：第一列 240px，第二列吃剩余空间。

### `grid-template-rows`

定义有几行，每行多高。

```css
.layout {
  grid-template-rows: 64px 1fr;
}
```

人话：第一行 64px，第二行吃剩余高度。

### `fr`

`fr` 是 Grid 里的份额单位。

```css
grid-template-columns: 1fr 2fr;
```

剩余空间分成 3 份，第一列 1 份，第二列 2 份。

## `repeat`

```css
.cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
```

等价于 `1fr 1fr 1fr`。

关键词认知：`repeat()` 只是少写重复代码，不改变 Grid 本质。

## `minmax`

```css
.cards {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
}
```

`minmax(0, 1fr)` 表示最小 0，最大吃一份空间。实际项目里它能减少内容把网格撑爆的问题。

## 自动响应式卡片

```css
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}
```

含义：

1. 每张卡片最小 `240px`。
2. 容器够宽就自动多放几列。
3. 容器不够宽就自动换行。
4. 每列最大平分剩余空间。

> [!success] 这是卡片网格神级模板
> 个人主页、后台卡片、文章列表、商品列表，都可以先从这个模板开始。

关键词认知：

| 关键字 | 人话解释 |
|---|---|
| `minmax(0, 1fr)` | 最小允许压到 0，最大吃 1 份空间 |
| `minmax(240px, 1fr)` | 最小 240px，最大吃剩余空间 |
| `auto-fit` | 自动计算能放几列，空列会收起来 |
| `auto-fill` | 自动计算能放几列，但倾向保留空列位置 |

做自适应卡片时，先用 `auto-fit`，更符合“有几张卡就铺几张”的直觉。

## 页面骨架布局

```css
.page {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-rows: 64px 1fr;
  min-height: 100vh;
}

.header {
  grid-column: 1 / -1;
}

.sidebar {
  grid-row: 2;
}

.main {
  grid-row: 2;
}
```

`1 / -1` 表示从第一条网格线到最后一条网格线。

## 命名区域

```css
.dashboard {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-rows: 64px 1fr;
  grid-template-areas:
    "header header"
    "sidebar main";
}

.header {
  grid-area: header;
}

.sidebar {
  grid-area: sidebar;
}

.main {
  grid-area: main;
}
```

命名区域更适合页面级布局，可读性强。

## Grid 和 Flex 怎么选

| 场景 | 推荐 |
|---|---|
| 一行按钮、导航、工具栏 | Flex |
| 垂直居中一个元素 | Flex |
| 左右两栏，右侧自适应 | Flex 或 Grid |
| 卡片网格 | Grid |
| 页面骨架 | Grid |
| 表单两列布局 | Grid |
| 复杂二维对齐 | Grid |

## 媒体查询

```css
.page {
  display: grid;
  grid-template-columns: 240px 1fr;
}

@media (max-width: 768px) {
  .page {
    grid-template-columns: 1fr;
  }

  .sidebar {
    display: none;
  }
}
```

媒体查询可以按视口宽度调整布局。

## 响应式关键字认知

### viewport

视口就是浏览器当前可见区域。手机端、桌面端最直接的差异就是视口宽度不同。

HTML 里通常要有：

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

没有它，移动端页面可能按桌面宽度缩放，导致字体小、布局怪。

### media query

媒体查询是“满足条件时才生效的一段 CSS”。

```css
@media (max-width: 768px) {
  .sidebar {
    display: none;
  }
}
```

人话：屏幕宽度不超过 768px 时，隐藏侧边栏。

### breakpoint

断点是布局发生变化的宽度。真正项目里，断点应该由内容决定。如果卡片在 880px 开始挤，就在 880px 附近调整，不必硬套某个框架断点。

## 移动优先写法

移动优先是先写小屏样式，再用 `min-width` 增强大屏。

```css
.cards {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
}

@media (min-width: 768px) {
  .cards {
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }
}

@media (min-width: 1024px) {
  .cards {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

> [!success] 推荐移动优先
> 现在用户大量来自移动端。先保证小屏可读，再增强大屏布局，通常更稳。

关键词认知：移动优先不是“只做手机”，而是默认样式先适配小屏，再通过 `@media (min-width: ...)` 往大屏增加列数、留白和复杂布局。

## 响应式常见策略

1. 容器最大宽度：`max-width` + `margin: 0 auto`。
2. 内容左右留白：`padding-inline`。
3. 图片自适应：`max-width: 100%`。
4. 卡片网格：`auto-fit + minmax`。
5. 字号节制：不要让标题在手机上过大。
6. 导航折叠：桌面横排，移动端收起或换行。

## 本章练习

1. 用 Grid 写一个三列卡片区。
2. 用 `auto-fit + minmax` 改成自适应。
3. 用命名区域写一个后台页面骨架。
4. 用媒体查询把桌面两列改成手机单列。
5. 用 DevTools 的设备模式测试手机宽度。

## 一句话总结

> Flex 管一条轴，Grid 管行列二维空间；响应式不是写很多断点，而是让布局天然有弹性。
