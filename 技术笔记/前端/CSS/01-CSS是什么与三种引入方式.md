---
title: CSS 01 - CSS 是什么与三种引入方式
tags:
  - 前端
  - CSS
  - HTML
created: 2026-06-18
up: "[[00-MOC-CSS从0基础到大神]]"
description: 理解 CSS 的职责、语法结构、三种引入方式、基础选择器和第一个页面样式。
---

# CSS 01 - CSS 是什么与三种引入方式

> [!tip] 先建立一句话模型
> HTML 负责内容结构，CSS 负责视觉表现，JavaScript 负责交互逻辑。CSS 的本质是：找到一批元素，然后给它们声明样式规则。

## CSS 解决什么问题

没有 CSS 时，页面只有结构：标题、段落、列表、链接、图片、表单。CSS 加上去以后，页面才有颜色、字体、间距、布局、响应式和动画。

常见职责：

1. 字体：字号、字重、行高、字体族。
2. 颜色：文字色、背景色、边框色。
3. 盒子：宽高、内边距、边框、外边距。
4. 布局：横排、竖排、居中、两列、三列、卡片网格。
5. 状态：hover、focus、active、disabled。
6. 响应式：手机、平板、桌面不同布局。
7. 动画：过渡、关键帧、变形。

## CSS 基本语法

```css
选择器 {
  属性名: 属性值;
  属性名: 属性值;
}
```

示例：

```css
.card {
  padding: 16px;
  border: 1px solid #d0d7de;
  border-radius: 8px;
  background: #ffffff;
}
```

这个规则表示：找到 class 是 `card` 的元素，然后给它设置内边距、边框、圆角和背景色。

## 三种引入方式

### 1. 行内样式

```html
<p style="color: red; font-size: 18px;">这是一段文字</p>
```

优点是直接，缺点是难维护、难复用、优先级很高。项目里只适合临时调试或极少量动态样式。

> [!warning] 不要把行内样式当主力
> 行内样式会让 HTML 和样式混在一起，后期改版时很痛苦。真正项目里，优先写到独立 CSS 文件或组件样式里。

### 2. 内部样式表

```html
<style>
  h1 {
    color: #0969da;
  }
</style>
```

适合小 demo、教学案例、单文件页面。缺点是多个页面无法复用。

### 3. 外部样式表

```html
<link rel="stylesheet" href="./style.css">
```

这是项目主流方式。HTML 放结构，CSS 独立维护，多个页面可以复用同一个样式文件。

## 第一个完整例子

HTML：

```html
<article class="profile-card">
  <h1>小明</h1>
  <p>前端学习者，正在学习 CSS 布局。</p>
  <a href="#">查看作品</a>
</article>
```

CSS：

```css
.profile-card {
  max-width: 360px;
  padding: 24px;
  border: 1px solid #d0d7de;
  border-radius: 8px;
  background: #ffffff;
}

.profile-card h1 {
  margin: 0 0 8px;
  font-size: 24px;
}

.profile-card p {
  margin: 0 0 16px;
  color: #57606a;
  line-height: 1.7;
}

.profile-card a {
  color: #0969da;
  text-decoration: none;
}
```

## 基础选择器先会这些

| 选择器 | 示例 | 含义 |
|---|---|---|
| 标签选择器 | `p` | 选中所有 `p` 标签 |
| 类选择器 | `.card` | 选中 `class="card"` 的元素 |
| ID 选择器 | `#app` | 选中 `id="app"` 的元素 |
| 后代选择器 | `.card p` | 选中 `.card` 里面所有 `p` |
| 子代选择器 | `.nav > a` | 选中 `.nav` 的直接子元素 `a` |
| 群组选择器 | `h1, h2, h3` | 同时选中多个选择器 |

> [!success] 项目建议
> 普通业务样式优先用 class 选择器。标签选择器适合做基础重置，ID 选择器少用，后代选择器不要嵌套太深。

## CSS 的执行方式

浏览器加载页面时，大致会做这些事：

1. 解析 HTML，生成 DOM 树。
2. 解析 CSS，生成 CSSOM。
3. 把 DOM 和 CSSOM 结合成渲染树。
4. 计算每个盒子的大小和位置。
5. 绘制像素到屏幕上。

这意味着 CSS 写错了不一定报错，浏览器会忽略它不认识的属性或无效值。所以学 CSS 必须学会用 DevTools 看计算结果。

## 常见错误

> [!danger] 新手最常见 5 个坑
> 1. 忘记给 HTML 引入 CSS 文件。
> 2. 文件路径写错，比如 `href="./style.css"` 但文件不在当前目录。
> 3. 选择器没命中元素。
> 4. 属性名拼错，比如把 `background` 写成 `backgroud`。
> 5. 写了样式但被后面的规则覆盖。

## 本章练习

1. 新建 `index.html` 和 `style.css`。
2. 写一个个人介绍卡片。
3. 给卡片加背景、边框、圆角、内边距。
4. 给标题、正文、按钮分别设置样式。
5. 打开 DevTools，查看每个元素最终生效的样式。

## 一句话总结

> CSS 的第一步不是背属性，而是理解“选择器命中元素，声明改变表现，浏览器计算最终样式”。

