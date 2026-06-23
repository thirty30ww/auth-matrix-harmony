# Auth Matrix Harmony

Auth Matrix 的 HarmonyOS 客户端，基于 ArkTS 开发。当前主要提供登录、个人信息维护、密码修改、登录日志查看和操作日志查看等功能。

## 项目信息

- 应用包名：`com.example.harmony`
- 应用版本：`1.0.0`
- 支持设备：`phone`、`tablet`
- 目标 SDK：`HarmonyOS 6.0.1(21)`
- 入口模块：`entry`
- 入口页面：`pages/Login`
- 网络权限：`ohos.permission.INTERNET`

## 已实现功能

### 登录与会话

- 用户名、密码登录。
- 登录成功后保存 `accessToken`、`refreshToken` 和用户名。
- 启动应用时读取本地登录状态，已登录时自动进入个人主页。
- 请求返回 401 时，会使用 `refreshToken` 尝试刷新登录状态。
- 支持退出登录，并清理本地会话信息。

![image-20260623210820745](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210820745.png)

### 个人主页

- 展示头像、姓名、个性签名。
- 展示用户名、性别、创建时间和角色信息。
- 提供编辑个人信息、修改密码入口。
- 底部提供个人主页、操作日志、登录日志三个页面切换入口。

![image-20260623210642754](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210642754.png)

### 编辑个人信息

- 支持修改姓名、性别和个性签名。
- 保存成功后返回个人主页，并刷新展示信息。
- 页面中保留头像修改入口。
- 当前预览器环境点击头像会提示暂不支持选择头像；代码中已预留 `/file/upload/image` 上传接口。

![image-20260623210658656](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210658656.png)

### 修改密码

- 支持输入当前密码、新密码和确认新密码。
- 提交后调用后端修改密码接口。
- 修改成功后返回个人主页，并显示成功提示。

![image-20260623210710141](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210710141.png)

### 操作日志

- 支持查看操作日志列表。
- 支持按操作人或操作描述搜索。
- 支持分页加载，滚动到底部自动加载更多。
- 列表展示模块、操作描述、操作类型、请求方法、状态码、请求路径、IP、耗时和创建时间。
- 点击日志可查看详情，包括基本信息、请求信息、时间信息、请求参数、响应参数和错误信息。

![image-20260623210727396](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210727396.png)

![image-20260623210746896](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210746896.png)

### 登录日志

- 支持查看登录日志列表。
- 支持按用户名搜索。
- 支持分页加载，滚动到底部自动加载更多。
- 列表展示用户名、登录状态、登录类型、耗时、IP、浏览器、操作系统、设备型号、创建时间和错误信息。

![image-20260623210803003](https://thirty30ww.oss-cn-hangzhou.aliyuncs.com/hosting/image-20260623210803003.png)

## 接口对接

默认后端地址配置在：

```text
entry/src/main/ets/services/api/httpClient.ets
```

当前默认值：

```ts
private baseURL: string = 'http://localhost:8080';
```

真机调试时通常需要改成后端服务在局域网中的 IP 地址，例如：

```ts
private baseURL: string = 'http://192.168.1.10:8080';
```

当前使用的接口：

| 功能 | 方法 | 路径 |
| --- | --- | --- |
| 登录 | POST | `/auth/login` |
| 刷新 Token | GET | `/auth/refresh` |
| 退出登录 | GET | `/auth/logout` |
| 获取当前用户 | GET | `/user/get` |
| 更新用户信息 | POST | `/user/update` |
| 修改密码 | POST | `/user/change-password` |
| 上传图片 | POST | `/file/upload/image` |
| 操作日志列表 | POST | `/log/operation/list` |
| 操作日志详情 | GET | `/log/operation/get` |
| 登录日志列表 | POST | `/log/login/list` |

## 目录结构

```text
harmony
├── AppScope
│   └── app.json5
├── entry
│   ├── src/main/ets
│   │   ├── entryability
│   │   ├── pages
│   │   ├── services/api
│   │   └── stores
│   ├── src/main/resources
│   └── build-profile.json5
├── build-profile.json5
├── hvigorfile.ts
└── oh-package.json5
```

主要源码说明：

- `entry/src/main/ets/pages/Login.ets`：登录页。
- `entry/src/main/ets/pages/Profile.ets`：个人主页。
- `entry/src/main/ets/pages/EditProfile.ets`：编辑个人信息页。
- `entry/src/main/ets/pages/ChangePassword.ets`：修改密码页。
- `entry/src/main/ets/pages/OperationLog.ets`：操作日志页。
- `entry/src/main/ets/pages/LoginLog.ets`：登录日志页。
- `entry/src/main/ets/services/api/httpClient.ets`：HTTP 请求封装、Token 注入和刷新逻辑。
- `entry/src/main/ets/services/api/*.ets`：后端接口封装。
- `entry/src/main/ets/stores/authStore.ets`：登录状态管理。
- `entry/src/main/ets/stores/authStorage.ets`：本地登录信息持久化。

## 运行方式

1. 使用 DevEco Studio 打开本项目。
2. 确认 HarmonyOS SDK 与项目配置匹配。
3. 启动 Auth Matrix 后端服务。
4. 按实际环境修改 `httpClient.ets` 中的 `baseURL`。
5. 选择模拟器或真机运行 `entry` 模块。

## 备注

- 当前项目以移动端个人中心和日志查看为主。
- 登录状态保存在 HarmonyOS `preferences` 中。
- 页面样式使用项目内的颜色资源和 SVG 图标资源。
- 测试目录中保留了基础 Hypium 测试模板。
