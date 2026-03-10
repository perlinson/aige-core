# Godot AI Agent CLI - 面向AI Agent的命令行接口

> 将 Godot 游戏引擎改造成可通过 CLI 完整操控的游戏引擎

## 📦 安装

1. 克隆项目到 Godot 项目的 `addons/godot-agent-cli/` 目录
2. 在 Godot 编辑器中: `项目` → `插件` → 启用 `Godot AI CLI`

## 🚀 快速开始

### 方式1: 编辑器内启动

1. 启用插件后，在编辑器中按 F5 或运行项目
2. 服务器默认在 `localhost:8765` 启动

### 方式2: 命令行启动

```bash
# 启动 Godot (headless 模式)
godot --headless --path /path/to/project

# 在另一个终端调用 API
curl http://localhost:8765/api/status
```

## 📡 API 参考

### P0 核心命令 (已实现)

#### 场景节点管理

```bash
# 创建节点
curl -X POST http://localhost:8765/api/node/create \
  -H "Content-Type: application/json" \
  -d '{"parent": "/root", "type": "Node2D", "name": "Player"}'

# 删除节点
curl -X POST http://localhost:8765/api/node/delete \
  -H "Content-Type: application/json" \
  -d '{"path": "/root/Player"}'

# 获取节点属性
curl "http://localhost:8765/api/node/get?path=/root/Player&property=position"

# 设置节点属性
curl -X POST http://localhost:8765/api/node/set \
  -H "Content-Type: application/json" \
  -d '{"path": "/root/Player", "property": "modulate", "value": {"r":1,"g":0,"b":0}}'

# 列出节点
curl "http://localhost:8765/api/node/list?root=/root&filter=Node2D"
```

#### 动画系统

```bash
# 创建动画
curl -X POST http://localhost:8765/api/anim/create \
  -H "Content-Type: application/json" \
  -d '{"scene": "/root", "name": "walk"}'

# 列出动画
curl "http://localhost:8765/api/anim/list?scene=/root"

# 添加轨道
curl -X POST http://localhost:8765/api/anim/add-track \
  -H "Content-Type: application/json" \
  -d '{"scene": "/root", "anim": "walk", "node_path": "/root/Player", "property": "position"}'

# 添加关键帧
curl -X POST http://localhost:8765/api/anim/add-key \
  -H "Content-Type: application/json" \
  -d '{"scene": "/root", "anim": "walk", "track_index": 0, "time": 0, "value": {"x":0,"y":0}}'

# 播放动画
curl -X POST http://localhost:8765/api/anim/play \
  -H "Content-Type: application/json" \
  -d '{"scene": "/root", "name": "walk", "speed": 1.0}'
```

#### 日志系统

```bash
# 查询日志
curl "http://localhost:8765/api/log/query?level=2&lines=50"

# 日志统计
curl "http://localhost:8765/api/log/stats"

# 写入日志
curl -X POST http://localhost:8765/api/log/write \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from AI!", "level": 1}'
```

#### 调试系统

```bash
# 添加断点
curl -X POST http://localhost:8765/api/debug/breakpoint/add \
  -H "Content-Type: application/json" \
  -d '{"script": "res://main.gd", "line": 25}'

# 删除断点
curl -X POST http://localhost:8765/api/debug/breakpoint/remove \
  -H "Content-Type: application/json" \
  -d '{"script": "res://main.gd", "line": 25}'

# 列出断点
curl "http://localhost:8765/api/debug/breakpoint/list"

# 获取堆栈追踪
curl "http://localhost:8765/api/debug/stacktrace"
```

#### 资源系统

```bash
# 加载资源
curl "http://localhost:8765/api/resource/load?path=res://icon.svg"

# 保存资源
curl -X POST http://localhost:8765/api/resource/save \
  -H "Content-Type: application/json" \
  -d '{"path": "res://icon.svg", "save_path": "res://icon_copy.svg"}'

# 获取资源类型
curl "http://localhost:8765/api/resource/type?path=res://icon.svg"
```

#### 编辑器操作

```bash
# 获取当前选择
curl "http://localhost:8765/api/editor/get-selection"

# 保存场景
curl -X POST http://localhost:8765/api/editor/save-scene"

# 获取打开的场景
curl "http://localhost:8765/api/editor/open-scenes"
```

### 服务器控制

```bash
# 获取服务器状态
curl "http://localhost:8765/api/status"

# 停止服务器
curl "http://localhost:8765/api/stop-server"

# 获取帮助
curl "http://localhost:8765/api/help"
curl "http://localhost:8765/api/help?command=node.create"
```

## 📁 项目结构

```
godot-agent-cli/
├── plugin.gd                      # 插件入口
├── src/
│   ├── cli/
│   │   ├── cli_server.gd           # HTTP服务器
│   │   ├── command_router.gd       # 命令路由器
│   │   ├── cli_command.gd          # 命令类
│   │   └── cli_response.gd         # 响应类
│   ├── commands/
│   │   ├── scene_commands.gd      # 场景节点命令
│   │   ├── anim_commands.gd       # 动画命令
│   │   ├── log_commands.gd       # 日志命令
│   │   ├── debug_commands.gd      # 调试命令
│   │   ├── editor_commands.gd     # 编辑器命令
│   │   └── resource_commands.gd   # 资源命令
│   └── utils/
│       ├── node_utils.gd          # 节点工具
│       └── variant_utils.gd        # 类型转换工具
└── icon.svg                       # 插件图标
```

## 🔧 配置

在 `project.godot` 中添加:

```ini
[editor_plugins]

enabled=["res://addons/godot-agent-cli/plugin.cfg"]
```

## 📋 已实现功能

| 模块 | 状态 | 命令数 |
|------|------|--------|
| 场景节点管理 | ✅ 完成 | 7 |
| 动画系统 | ✅ 完成 | 5 |
| 日志系统 | ✅ 完成 | 3 |
| 调试系统 | ✅ 完成 | 4 |
| 资源系统 | ✅ 完成 | 3 |
| 编辑器操作 | ✅ 完成 | 3 |
| **P0 小计** | **✅ 完成** | **25** |
| **2D对象系统** | ✅ 完成 | 7 |
| **物理系统(2D)** | ✅ 完成 | 5 |
| **UI系统** | ✅ 完成 | 5 |
| **音频系统** | ✅ 完成 | 6 |
| **导航系统(2D)** | ✅ 完成 | 5 |
| **输入系统** | ✅ 完成 | 5 |
| **脚本系统** | ✅ 完成 | 6 |
| **项目设置** | ✅ 完成 | 6 |
| **构建导出** | ✅ 完成 | 3 |
| **P1 小计** | **✅ 完成** | **43** |
| **总计** | **✅ 68命令** | |

## 🎯 待实现 (P2)

- 粒子系统
- 网络系统
- 着色器/材质
- 插件系统
- 版本控制 (VCS)
- 渲染设置

---

**版本**: 1.0.0 | **目标**: Godot 4.x
