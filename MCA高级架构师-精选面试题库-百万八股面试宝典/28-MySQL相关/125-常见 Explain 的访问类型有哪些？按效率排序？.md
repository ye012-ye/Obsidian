从高到低：  
`system`（单行）→ `const` → `eq_ref` → `ref` → `range` → `index` → `ALL`（全表扫描）。理想常见类型为 `ref` 或 `range`，避免 `ALL`。
