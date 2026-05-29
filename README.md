# 奇迹塔防 (Miracle Tower Defense)

> 跨越量子微观到宇宙奇点的塔防史诗 · Godot 4.6.3 · 两人团队

## 项目结构

```
QJTF/
├── project.godot              # Godot 项目配置
├── scenes/                    # 场景文件 (.tscn)
│   ├── main_menu.tscn
│   └── game.tscn
├── scripts/                   # GDScript 游戏逻辑
│   ├── game_state.gd           # Autoload 全局状态
│   ├── game_manager.gd         # 主控制器
│   ├── wave_manager.gd         # 波次管理
│   ├── enemy.gd                # 敌人基类
│   ├── tower.gd                # 塔基类
│   ├── hud.gd                  # 游戏界面
│   ├── main_menu.gd            # 主菜单
│   ├── enemies/                # 各纪元敌人
│   │   ├── virtual_particle.gd
│   │   ├── free_electron.gd
│   │   ├── proton_cluster.gd
│   │   └── boss_entanglement.gd
│   └── towers/                 # 各纪元塔
│       ├── probability_tower.gd
│       ├── observer_tower.gd
│       └── quark_trap.gd
├── assets/                     # 游戏资源
│   ├── sprites/                # 精灵图 (AI生成)
│   ├── maps/                   # 地图数据
│   └── sounds/                 # 音效
├── ai_assets/                  # AI 美术管线
│   ├── prompts/                # 提示词模板
│   └── generated/              # 生成图片
├── docs/                       # 设计文档
│   └── 奇迹塔防_游戏策划案.md
├── README.md
└── .gitignore
```

## 子项目/Agent 划分

为避免上下文过长，项目按以下边界拆分为独立工作区：

### Agent 1: Core Engine（核心引擎）
- **目录：** `scripts/`, `scenes/`
- **职责：** 游戏逻辑、场景、UI、波次系统
- **入口：** `project.godot` → `game.tscn`

### Agent 2: AI Art Pipeline（美术管线）
- **目录：** `ai_assets/`
- **职责：** Pollinations 图片生成、提示词工程、素材管理
- **入口：** `ai_assets/generate.py`

### Agent 3: Design & Docs（策划文档）
- **目录：** `docs/`
- **职责：** 策划案维护、关卡数据表、平衡性设计

## 快速开始

1. 用 Godot 4.6.3 打开 `project.godot`
2. 运行主场景 `scenes/main_menu.tscn`
3. 点击「开始游戏」进入第一关

## 开发状态

| 纪元 | 关卡 | 塔 | 敌人 | 状态 |
|------|------|-----|------|------|
| 量子微观 | 1/3 | 3 | 3+Boss | 🔨 MVP 开发中 |
| 生命起源 | 0 | 0 | 0 | ⏳ |
| 原始觉醒 | 0 | 0 | 0 | ⏳ |
| 工业文明 | 0 | 0 | 0 | ⏳ |
| 现代文明 | 0 | 0 | 0 | ⏳ |
| 星际未来 | 0 | 0 | 0 | ⏳ |
| 宇宙奇点 | 0 | 0 | 0 | ⏳ |
