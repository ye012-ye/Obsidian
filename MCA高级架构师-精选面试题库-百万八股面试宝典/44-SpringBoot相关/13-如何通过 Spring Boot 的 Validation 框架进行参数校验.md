在 Spring Boot 中，我们通常通过 Hibernate Validator 来实现参数校验，并使用 `@RestControllerAdvice` 对异常统一处理。具体步骤如下：

M

### 1. 添加校验依赖

在 `pom.xml` 中加入：

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

这样系统便会引入 Hibernate Validator 实现。

### 2. 在 DTO 或参数上添加注解

```java
public class UserDto {
    @NotBlank(message = "用户名不能为空")
    private String username;

    @Min(value = 0, message = "年龄不能小于0")
    @Max(value = 200, message = "年龄不能超过200")
    private Integer age;

    @NotBlank(message = "邮件地址不能为空")
    @Email(message = "邮件格式不正确")
    private String email;
}
```

在 Controller 方法中使用 `@Valid`（或 `@Validated`）标记参数，如：

```java
@PostMapping("/user")
public ResponseResult create(@RequestBody @Valid UserDto dto) {
    return ResponseResult.ok(dto);
}
```

对普通参数校验时，可在类上加 `@Validated`，并在参数上使用注解：

```java
@RestController
@Validated
public class UserController {
    @GetMapping("/check")
    public ResponseResult check(@NotBlank(message = "名称不能为空") String name) {
        return ResponseResult.ok(name);
    }
}
```

S

### 3. 统一处理校验异常

创建统一异常处理类：

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Map<String,String> handleValid(MethodArgumentNotValidException ex) {
        Map<String,String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(err ->
                                                       errors.put(err.getField(), err.getDefaultMessage()));
        return errors;
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(ConstraintViolationException.class)
    public Map<String,String> handleConstraint(ConstraintViolationException ex) {
        Map<String,String> errors = new HashMap<>();
        ex.getConstraintViolations().forEach(v ->
                                             errors.put(v.getPropertyPath().toString(), v.getMessage()));
        return errors;
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(BindException.class)
    public Map<String,String> handleBind(BindException ex) {
        Map<String,String> errors = new HashMap<>();
        ex.getFieldErrors().forEach(err ->
                                    errors.put(err.getField(), err.getDefaultMessage()));
        return errors;
    }
}
```

这段代码会捕获以下三种异常类型，并格式化返回对应字段的错误信息 。

- `MethodArgumentNotValidException`：`@Valid @RequestBody` 校验失败
- `ConstraintViolationException`：普通参数校验失败
- `BindException`：表单或对象绑定失败

B

### 4. 运行效果与逻辑分析

- 参数不合法时直接反馈 HTTP 400 状态码，body 中包含完整的校验错误集合。
- 前端只需解析返回结果即可，清楚知道哪些字段不满足要求。
- 确保校验逻辑与业务逻辑分离，校验模块化、维护性高。
