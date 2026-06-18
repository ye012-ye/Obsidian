---
title: JavaScript 数组、对象、集合与常用 API
tags:
  - JavaScript
  - 数组
  - 对象
  - API
created: 2026-06-13
up: "[[00-MOC-JavaScript从0基础到大神]]"
description: 掌握数组方法、对象操作、解构、展开、Map、Set、JSON 和项目中最常用的数据处理套路。
---
 
# JavaScript 数组、对象、集合与常用 API

> [!info] 本章抓什么
> 前端大部分代码都在处理数据：后端返回数组，页面渲染列表，用户点击后更新对象。数组和对象熟不熟，直接决定你写业务是否顺手。

## 数组基础

```js
const users = ["张三", "李四", "王五"];

console.log(users[0]);
console.log(users.length);

users.push("赵六");
users.pop();
```

常用增删：

| 方法 | 作用 | 是否改变原数组 |
|---|---|---:|
| `push` | 末尾添加 | 是 |
| `pop` | 末尾删除 | 是 |
| `unshift` | 开头添加 | 是 |
| `shift` | 开头删除 | 是 |
| `slice` | 截取 | 否 |
| `splice` | 删除/替换/插入 | 是 |

## map、filter、find、some、every

```js
const products = [
  { id: 1, name: "键盘", price: 199, stock: 5 },
  { id: 2, name: "鼠标", price: 99, stock: 0 },
  { id: 3, name: "显示器", price: 999, stock: 2 },
];

const names = products.map((item) => item.name);
const available = products.filter((item) => item.stock > 0);
const keyboard = products.find((item) => item.name === "键盘");
const hasExpensive = products.some((item) => item.price > 500);
const allInStock = products.every((item) => item.stock > 0);
```

| 方法 | 返回值 | 使用场景 |
|---|---|---|
| `map` | 新数组 | 转换数据 |
| `filter` | 新数组 | 过滤数据 |
| `find` | 单个元素或 `undefined` | 找第一条 |
| `some` | 布尔值 | 是否存在 |
| `every` | 布尔值 | 是否全部满足 |

## reduce

`reduce` 适合把数组汇总成一个结果。

```js
const total = products.reduce((sum, item) => {
  return sum + item.price * item.stock;
}, 0);

console.log(total);
```

按状态分组：

```js
const orders = [
  { id: 1, status: "paid" },
  { id: 2, status: "pending" },
  { id: 3, status: "paid" },
];

const group = orders.reduce((result, order) => {
  const key = order.status;
  result[key] ??= [];
  result[key].push(order);
  return result;
}, {});
```

> [!warning] 不要为了炫技滥用 reduce
> 如果 `map`、`filter`、`for...of` 更清楚，就用更清楚的写法。工程代码第一目标是可读。

## 对象基础

```js
const user = {
  id: 1,
  name: "小明",
  profile: {
    city: "杭州",
  },
};

console.log(user.name);
console.log(user["name"]);
```

动态属性：

```js
const key = "name";
console.log(user[key]);
```

## 解构与展开

```js
const { name, profile: { city } } = user; //name:user.namne ,city:user.profile.city
const [first, second] = ["A", "B", "C"];

const newUser = {
  ...user,
  name: "小红",
};

const newList = [...products, { id: 4, name: "耳机", price: 299, stock: 10 }];
```

> [!danger] 展开是浅拷贝
> `{ ...user }` 只复制第一层。嵌套对象还是同一个引用。Vue 状态更新、表单编辑、缓存修改时经常因此踩坑。

```js
const a = { profile: { city: "杭州" } };
const b = { ...a };

b.profile.city = "上海";
console.log(a.profile.city); // 上海
```

## 可选链与空值合并

```js
const cityName = user.profile?.city ?? "未知城市";
```

| 写法 | 作用 |
|---|---|
| `obj?.a?.b` | 前面为空就停止访问 |
| `value ?? defaultValue` | 只有 `null` 或 `undefined` 才用默认值 |

## Map 与 Set

`Set` 适合去重：

```js
const ids = [1, 2, 2, 3, 3, 3];
const uniqueIds = [...new Set(ids)];
```

`Map` 适合用任意值做 key：

```js
const cache = new Map();
cache.set("user:1", { id: 1, name: "小明" });
console.log(cache.get("user:1"));
```

## JSON

```js
const text = JSON.stringify(user);
const parsed = JSON.parse(text);
```

项目里常见用途：

1. 接口传输数据。
2. `localStorage` 存对象。
3. 深拷贝简单对象。

> [!warning] JSON 深拷贝有限制
> `JSON.parse(JSON.stringify(obj))` 会丢失函数、`undefined`、`Date` 类型、`Map`、`Set`，不要无脑使用。

## 常见数据处理套路

### 后端列表转下拉框

```js
const options = users.map((user) => ({
  label: user.name,
  value: user.id,
}));
```

### 按 id 快速查找

```js
const userMap = new Map(users.map((user) => [user.id, user]));
const target = userMap.get(1);
```

### 删除一条

```js
const nextProducts = products.filter((item) => item.id !== 2);
```

### 更新一条

```js
const updatedProducts = products.map((item) =>
  item.id === 1 ? { ...item, stock: item.stock + 1 } : item
);
```

## 本章练习

1. 把商品数组转成 `{ label, value }` 下拉数据。
2. 过滤库存大于 0 的商品。
3. 计算购物车总价。
4. 用 `Map` 根据用户 id 快速查找用户。
5. 用不可变写法更新数组中的一条记录。

## 一句话总结

> 前端业务开发的基本功，就是把数组和对象变成页面真正需要的形状。
