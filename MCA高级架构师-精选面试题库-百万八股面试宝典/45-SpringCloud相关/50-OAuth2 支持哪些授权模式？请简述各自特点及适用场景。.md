OAuth 2.0 定义了多种授权模式，用于不同类型的客户端和安全场景。当前主流模式包括以下几种：

**授权码模式（Authorization Code Grant）**：这是最安全、最常用的模式之一。客户端（后端应用）通过浏览器将用户引导至授权服务器，用户授权后返回一个授权码，客户端再通过后端安全通道交换获取 access token 和 refresh token。适用于需要保护 client\_secret 的 web 应用及移动应用，推荐搭配 PKCE 扩展以提高安全性。M

**客户端凭证模式（Client Credentials Grant）**：用于机器对机器的场景（例如服务之间的调用），客户端直接使用自身的 client\_id 和 client\_secret 获取 access token，无需用户参与。适用于后台任务、微服务间通信等纯服务器场景。S

**资源所有者密码模式（Resource Owner Password Credentials Grant）**：客户端直接收集用户用户名和密码，然后向授权服务器获取令牌。这种方式实现简便但存在较大安全风险，仅适用于高度信任的应用环境，现代应用中不推荐使用。B

**刷新令牌模式（Refresh Token Grant）**：当 access token 过期后，客户端可以使用已获得的 refresh token 向授权服务器请求新的 access token，无需用户重新登录。通常与授权码模式搭配使用，提升用户体验与安全性。

**设备授权模式（Device Code Grant）**：适用于没有输入界面或输入受限的设备（如智能电视、IoT 设备）。设备展示一个用户码和链接，用户在另一台设备上完成授权后，设备轮询服务器获取 access token，适用于交互受限设备的场景。  
此外还有 **JWT Bearer Grant、业界自定义扩展 Grant 类型** 等，适用于特定企业或系统间信任模型，授权服务器可依据 RFC 6749 扩展定义新类型。
