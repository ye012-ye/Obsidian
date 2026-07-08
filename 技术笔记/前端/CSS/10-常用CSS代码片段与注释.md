---
title: CSS 10 - 常用 CSS 代码片段与注释
tags:
  - 前端
  - CSS
  - 速查
created: 2026-07-03
up: "[[00-MOC-CSS从0基础到大神]]"
description: 整理项目里高频使用的 CSS 代码片段，包含基础重置、变量、布局、文本、组件、响应式和调试辅助。
---

# CSS 10 - 常用 CSS 代码片段与注释

> [!tip] 使用方式
> 这些不是必须一次性全放进项目的“万能 CSS”。需要哪一段，就复制哪一段；全局 reset、变量、容器可以放公共样式，按钮、卡片、表单更适合按组件拆开。

## 基础重置

```css
/* 让 width/height 包含 padding 和 border，布局时更符合直觉 */
*,
*::before,
*::after {
  box-sizing: border-box;
}

/* 去掉浏览器默认外边距，避免页面四周出现莫名空白 */
body {
  margin: 0;
  min-height: 100vh;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  line-height: 1.5;
  color: #111827;
  background: #ffffff;
}

/* 图片、视频默认自适应父容器，避免撑破布局 */
img,
svg,
video,
canvas {
  display: block;
  max-width: 100%;
}

/* 表单控件继承字体，避免 input/button 字体和页面不一致 */
input,
button,
textarea,
select {
  font: inherit;
}

/* 按钮默认可点击，去掉部分浏览器自带边框 */
button {
  cursor: pointer;
  border: 0;
}

/* 链接默认继承文字颜色，具体颜色交给业务样式决定 */
a {
  color: inherit;
  text-decoration: none;
}
```

## 设计变量

```css
:root {
  /* 颜色变量：统一管理主题色，后期换主题更方便 */
  --color-primary: #2563eb;
  --color-success: #16a34a;
  --color-danger: #dc2626;
  --color-text: #111827;
  --color-muted: #6b7280;
  --color-border: #e5e7eb;
  --color-surface: #ffffff;

  /* 间距变量：用固定阶梯减少到处写魔法数字 */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;

  /* 圆角和阴影：组件视觉保持统一 */
  --radius-sm: 4px;
  --radius-md: 8px;
  --shadow-card: 0 8px 24px rgb(15 23 42 / 8%);
}
```

## 容器与页面骨架

```css
/* 常用内容容器：左右留白，最大宽度不无限拉长 */
.container {
  width: min(100% - 32px, 1120px);
  margin-inline: auto;
}

/* 页面主体：至少撑满一屏，适合后台、详情页、表单页 */
.page {
  min-height: 100vh;
  background: #f9fafb;
}

/* 左侧菜单 + 右侧内容的常见后台布局 */
.page-shell {
  display: grid;
  grid-template-columns: 240px minmax(0, 1fr);
  min-height: 100vh;
}

/* 右侧内容允许收缩，避免长文本或表格把页面撑爆 */
.page-main {
  min-width: 0;
  padding: 24px;
}
```

## Flex 常用布局

```css
/* 水平垂直居中：按钮图标、空状态、弹窗内容都常用 */
.flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 左右分布：标题 + 操作按钮、logo + 用户信息 */
.flex-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

/* 自动换行的一组元素：标签、按钮组、筛选条件 */
.cluster {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

/* Flex 子项很容易被长文本撑开，加 min-width: 0 才能正确省略 */
.flex-item {
  min-width: 0;
  flex: 1;
}
```

## Grid 常用布局

```css
/* 响应式卡片网格：空间够就多列，不够自动变少 */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

/* 两列详情布局：左边说明，右边内容 */
.detail-grid {
  display: grid;
  grid-template-columns: 120px minmax(0, 1fr);
  gap: 12px 16px;
}

/* 固定比例区域：封面图、视频封面、预览图都适合 */
.ratio-box {
  aspect-ratio: 16 / 9;
  overflow: hidden;
  border-radius: 8px;
  background: #f3f4f6;
}
```

## 文本处理

```css
/* 单行省略：标题、表格单元格、导航文本常用 */
.text-ellipsis {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

/* 多行省略：卡片描述、列表摘要常用 */
.text-clamp-2 {
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

/* 长单词、URL、连续英文不撑破容器 */
.break-anywhere {
  overflow-wrap: anywhere;
}

/* 次要文字：时间、描述、辅助说明 */
.muted {
  color: #6b7280;
  font-size: 14px;
}
```

## 常见组件

```css
/* 卡片：适合列表项、统计块、表单分组 */
.card {
  padding: 16px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  box-shadow: var(--shadow-card);
}

/* 主按钮：显式命令，比如保存、提交、确认 */
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 36px;
  padding: 0 14px;
  border-radius: 6px;
  color: #ffffff;
  background: var(--color-primary);
}

/* 按钮 hover 只做轻微反馈，不要让布局尺寸变化 */
.button:hover {
  background: #1d4ed8;
}

/* 输入框：统一高度、边框、聚焦态 */
.input {
  width: 100%;
  min-height: 36px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  background: #ffffff;
}

.input:focus {
  outline: 2px solid rgb(37 99 235 / 20%);
  border-color: var(--color-primary);
}
```

## 定位、层级与滚动

```css
/* 吸顶区域：表头、导航栏、筛选条 */
.sticky-top {
  position: sticky;
  top: 0;
  z-index: 10;
  background: #ffffff;
}

/* 弹窗遮罩：固定覆盖整个视口 */
.overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background: rgb(15 23 42 / 45%);
}

/* 内部滚动区域：列表、侧栏、弹窗内容 */
.scroll-area {
  overflow: auto;
  overscroll-behavior: contain;
}
```

## 可访问性与状态

```css
/* 视觉隐藏，但屏幕阅读器仍可读取 */
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* 键盘聚焦时给清晰边框，鼠标点击时通常不显示 */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* 禁用态：同时处理鼠标和视觉反馈 */
.is-disabled,
:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}
```

## 响应式常用写法

```css
/* 小屏时后台两列布局改成单列 */
@media (max-width: 768px) {
  .page-shell {
    grid-template-columns: 1fr;
  }

  .page-main {
    padding: 16px;
  }
}

/* 用户系统开启减少动态效果时，关闭大部分动画 */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## 调试辅助

```css
/* 临时打开元素轮廓，用来排查是谁把页面撑宽了 */
.debug * {
  outline: 1px solid rgb(220 38 38 / 35%);
}

/* 临时标出滚动容器，排查 sticky 或 overflow 问题 */
.debug-scroll {
  outline: 2px dashed #f59e0b;
  background: rgb(245 158 11 / 8%);
}
```

## 记忆口诀

> [!success] 常用 CSS 顺序
> 先 reset，再变量；先容器，再布局；先文本，再组件；最后补响应式、状态和调试辅助。

## 相关笔记

- [[03-盒模型尺寸单位颜色与字体]]
- [[05-Flex布局从入门到实战]]
- [[06-Grid布局响应式与媒体查询]]
- [[08-CSS工程化BEM变量预处理器与组件化]]
- [[09-调试性能兼容性与面试避坑]]
