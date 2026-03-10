# AIGE-Core 🎮⚡

> AI Godot Engine - Core CLI Interface

将 Godot 游戏引擎改造成可通过 CLI 完整操控的、面向 AI Agent 的游戏开发引擎。

[![Godot Version](https://img.shields.io/badge/Godot-4.x-blue)](https://godotengine.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange)](https://github.com/perlinson/aige-core)

## ✨ 特性

- 🤖 **AI 驱动开发** - 通过 HTTP API 完整控制 Godot 引擎
- 🎮 **全功能覆盖** - 68+ CLI 命令覆盖所有核心模块
- ⚡ **实时操作** - 创建节点、动画、UI、物理、音频...
- 📡 **简单集成** - RESTful API 设计，JSON 格式通信

## 🚀 快速开始

### 1. 安装

```bash
# 克隆项目到 Godot 项目的 addons 目录
git clone https://github.com/perlinson/aige-core.git addons/aige_core
```

### 2. 启用插件

在 Godot 编辑器中：`项目` → `插件` → 启用 `AIGE-Core`

### 3. 启动服务器

```bash
# 运行项目，服务器默认在 localhost:8765 启动
godot --headless --path /path/to/project
```

### 4. 使用 API

```bash
# 创建节点
curl -X POST http://localhost:8765/api/node/create \
  -H "Content-Type: application/json" \
  -d '{"parent": "/root", "type": "Node2D", "name": "Player"}'

# 查询日志
curl "http://localhost:8765/api/log/query?level=2&lines=50"
```

## 📡 API 参考

### 核心命令 (P0)

| 模块 | 命令数 | 功能 |
|------|--------|------|
| `node.*` | 7 | 场景节点创建/删除/属性 |
| `anim.*` | 5 | 动画系统 |
| `log.*` | 3 | 日志查询 |
| `debug.*` | 4 | 断点/堆栈追踪 |
| `resource.*` | 3 | 资源加载/保存 |
| `editor.*` | 3 | 编辑器操作 |

### 扩展命令 (P1)

| 模块 | 命令数 | 功能 |
|------|--------|------|
| `2d.*` | 7 | 2D 对象 (Sprite, Camera, TileMap...) |
| `physics.*` | 5 | 物理系统 (刚体, 碰撞, 射线...) |
| `ui.*` | 5 | UI 系统 (容器, 控件...) |
| `audio.*` | 6 | 音频系统 (播放器, 总线...) |
| `nav.*` | 5 | 导航系统 (区域, 路径...) |
| `input.*` | 5 | 输入系统 (动作, 模拟...) |
| `script.*` | 6 | 脚本系统 (创建, 附加...) |
| `project.*` | 6 | 项目设置 |
| `build.*` | 3 | 构建导出 |

**总计**: 68+ 命令

详细 API 文档见 [API.md](docs/API.md)

## 📁 项目结构

```
AIGE-Core/
├── addons/
│   └── aige_core/
│       ├── plugin.gd              # 插件入口
│       ├── plugin.cfg             # 插件配置
│       ├── src/
│       │   ├── cli/
│       │   │   ├── cli_server.gd      # HTTP 服务器
│       │   │   ├── command_router.gd # 命令路由
│       │   │   ├── cli_command.gd    # 命令类
│       │   │   └── cli_response.gd   # 响应类
│       │   ├── commands/
│       │   │   ├── scene_commands.gd     # 场景节点
│       │   │   ├── anim_commands.gd      # 动画
│       │   │   ├── log_commands.gd       # 日志
│       │   │   ├── debug_commands.gd     # 调试
│       │   │   ├── resource_commands.gd  # 资源
│       │   │   ├── editor_commands.gd    # 编辑器
│       │   │   ├── twod_commands.gd      # 2D对象
│       │   │   ├── physics_commands.gd   # 物理
│       │   │   ├── ui_commands.gd        # UI
│       │   │   ├── audio_commands.gd     # 音频
│       │   │   ├── nav_commands.gd       # 导航
│       │   │   ├── input_commands.gd     # 输入
│       │   │   ├── script_commands.gd    # 脚本
│       │   │   ├── project_commands.gd   # 项目
│       │   │   └── build_commands.gd     # 构建
│       │   └── utils/
│       │       ├── node_utils.gd     # 节点工具
│       │       └── variant_utils.gd  # 类型转换
│       └── icon.svg                  # 插件图标
├── docs/
│   └── API.md                        # API 文档
└── README.md                         # 本文件
```

## 🛠️ AI Agent 使用示例

### Python SDK

```python
import requests

class AIGEClient:
    def __init__(self, host="localhost", port=8765):
        self.base_url = f"http://{host}:{port}/api"
    
    def create_node(self, parent, node_type, name):
        return requests.post(f"{self.base_url}/node/create", json={
            "parent": parent, "type": node_type, "name": name
        }).json()
    
    def play_animation(self, scene, name):
        return requests.post(f"{self.base_url}/anim/play", json={
            "scene": scene, "name": name
        }).json()

# 使用
client = AIGEClient()
client.create_node("/root", "Node2D", "Player")
```

### 创建完整游戏场景

```bash
# 1. 创建玩家
curl -X POST http://localhost:8765/api/node/create \
  -d '{"parent": "/root", "type": "Node2D", "name": "Player"}'

# 2. 添加 Sprite
curl -X POST http://localhost:8765/api/2d/sprite/create \
  -d '{"parent": "/root/Player", "texture": "res://icon.svg"}'

# 3. 添加物理
curl -X POST http://localhost:8765/api/physics/create-body \
  -d '{"parent": "/root/Player", "type": "RigidBody2D"}'

# 4. 添加背景音乐
curl -X POST http://localhost:8765/api/audio/create-player \
  -d '{"parent": "/root", "stream": "res://music.ogg"}'

# 5. 播放音乐
curl -X POST http://localhost:8765/api/audio/play \
  -d '{"player": "/root/AudioStreamPlayer2D"}'
```

## 🔧 开发

### 本地开发

```bash
# 1. 克隆项目
git clone https://github.com/perlinson/aige-core.git

# 2. 创建测试项目
mkdir my-game && cd my-game
godot --create-project .

# 3. 链接插件
ln -s ../aige-core addons/aige_core

# 4. 运行测试
godot --editor --headless
```

### 运行测试

```bash
# 测试 API
curl http://localhost:8765/api/status
# {"success":true,"running":true,"port":8765,"version":"1.0.0"}
```

## 📜 许可证

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 致谢

- [Godot Engine](https://godotengine.org) - 伟大的开源游戏引擎
- [OpenClaw](https://github.com/openclaw/openclaw) - 本AI Agent的运行环境

---

**让 AI Agent 能够独立开发游戏！** 🎮🤖
