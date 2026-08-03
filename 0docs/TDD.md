# 技术设计文档（TDD）Demo 版
> 对应 GDD v0.1，范围限定为 Demo 可演示版本
> 引擎：Godot 4.x
> 目标：架构完整、核心循环闭环、代码规范、可作为简历项目展示

---

## 一、文档概述

### 1.1 目的
本文档定义 Demo 版本的技术架构、模块划分、接口规范与实现方案，指导开发并保证代码可扩展、可维护，为后续完整版本预留扩展空间。

### 1.2 范围
Demo 仅实现以下核心内容：
- 赤焰属性完整战斗 + 生产体系（4 战斗技能 + 4 生产技能）
- 3 个房间场景（初始房间 × 1、赤焰外围 × 1、赤焰据点 × 1）
- 2 种赤焰属性怪物
- 基础修炼系统（第一境前 5 级）
- 锻造生产系统雏形
- 背包与物品基础系统

### 1.3 架构原则
1. **模块化**：单一职责，每个系统独立成管理器
2. **事件驱动**：系统间通过事件总线通信，低耦合
3. **数据驱动**：所有数值配置化，代码不写死数值
4. **表现逻辑分离**：业务逻辑与视觉表现分层，预留网络扩展
5. **面向接口**：实体统一接口，新增类型无需修改核心逻辑

---

## 二、整体架构

### 2.1 分层架构

```
┌─────────────────────────────────┐
│ 表现层（View）                   │  场景节点、动画、特效、UI
│  Player / Enemy / 特效 / UI     │
├─────────────────────────────────┤
│ 逻辑层（Logic）                  │  业务规则计算
│  战斗 / 技能 / 修炼 / 锻造       │
├─────────────────────────────────┤
│ 数据层（Data）                   │  配置资源、运行时状态
│  SkillData / EnemyData / 存档    │
├─────────────────────────────────┤
│ 基础服务层（Managers）           │  全局单例管理器
│  EventBus / GameManager / ...    │
└─────────────────────────────────┘
```

### 2.2 核心设计模式
- **单例模式**：全局管理器使用 Godot AutoLoad（自动加载）
- **观察者模式**：EventBus 事件总线解耦模块
- **策略模式**：技能基类 + 子类实现，不同技能不同策略
- **接口模式**：IDamageable 统一受伤接口
- **资源模式**：所有配置用 `.tres` 资源，数据驱动

---

## 三、项目目录结构

```
project/
├── docs/                     # 文档（GDD、TDD）
├── scenes/
│   ├── entities/              # 实体场景
│   │   ├── player.tscn        # 玩家
│   │   └── enemies/           # 怪物
│   ├── rooms/                 # 房间场景（每个房间独立tscn）
│   │   ├── room_start.tscn
│   │   ├── room_flame_1.tscn
│   │   └── room_flame_town.tscn
│   ├── skills/                # 技能特效场景
│   ├── items/                 # 掉落物场景
│   └── ui/                    # UI界面
│       ├── hud/
│       ├── panels/
│       └── components/
├── scripts/
│   ├── managers/              # 全局管理器（AutoLoad）
│   │   ├── event_bus.gd
│   │   ├── game_manager.gd
│   │   ├── battle_manager.gd
│   │   ├── skill_system.gd
│   │   ├── energy_system.gd
│   │   ├── room_manager.gd
│   │   ├── ui_manager.gd
│   │   └── inventory_system.gd
│   ├── entities/              # 实体脚本
│   │   ├── entity_base.gd     # 实体基类
│   │   ├── player.gd
│   │   └── enemy_base.gd
│   ├── skills/                # 技能脚本
│   │   ├── skill_base.gd      # 技能基类
│   │   └── flame/             # 赤焰技能
│   ├── systems/               # 子系统
│   │   ├── forge_system.gd    # 锻造系统
│   │   └── buff_system.gd     # 状态效果系统
│   ├── data/                  # 数据资源脚本
│   │   ├── skill_data.gd
│   │   ├── enemy_data.gd
│   │   ├── item_data.gd
│   │   └── room_data.gd
│   └── utils/                 # 工具函数
├── data/                      # 配置资源（.tres）
│   ├── skills/
│   ├── enemies/
│   ├── items/
│   └── rooms/
└── assets/                    # 美术、音效资源
```

---

## 四、核心模块设计

所有管理器均为 Godot **AutoLoad 自动加载单例**，全局可访问。

### 4.1 EventBus（事件总线）
- **职责**：全局事件中心，所有系统间通信通过信号完成，不直接引用
- **核心信号**：
  ```
  signal entity_damaged(attacker, target, damage_info)
  signal entity_died(entity)
  signal energy_changed(attribute, amount)
  signal level_up(attribute, new_level)
  signal item_picked(item)
  signal room_loaded(room_data)
  signal skill_casted(skill_id, caster)
  ```
- **设计意义**：解耦模块，新增系统不影响现有代码；未来加网络只需在此层拦截事件同步

### 4.2 GameManager
- **职责**：游戏全局状态管理、场景切换调度、游戏流程控制
- **状态枚举**：主菜单、游戏中、暂停、死亡、对话
- **核心接口**：
  - `change_room(room_id)`：切换房间场景
  - `game_over()`：玩家死亡处理
  - `pause_game()` / `resume_game()`

### 4.3 BattleManager（战斗管理器）
- **职责**：统一伤害计算入口、伤害数值校验、伤害数字派发
- **核心接口**：
  - `deal_damage(caster, target, damage_info)`：统一伤害结算
  - 伤害公式：`最终伤害 = 基础伤害 × 属性加成 × (1 - 防御减伤) × 暴击倍率`
- **DamageInfo 结构**：
  ```gdscript
  var damage: float
  var element: String  # flame / life / frost / shadow
  var is_crit: bool = false
  var knockback: Vector2
  var source_id: String
  ```
- **IDamageable 接口**：所有可受伤实体实现 `take_damage(damage_info)` 方法

### 4.4 SkillSystem（技能系统）
- **职责**：技能冷却管理、技能施放校验、技能实例创建
- **SkillBase 基类字段**：
  ```gdscript
  extends Node2D
  class_name SkillBase
  
  @export var data: SkillData
  var state: int = SKILL_STATE.IDLE
  var cooldown_timer: float = 0.0
  
  enum SKILL_STATE { IDLE, CASTING, COOLDOWN }
  
  func can_cast() -> bool: ...
  func cast(caster): ...
  func _process(delta): ...
  ```
- **技能分类**：投射物技能、范围技能、近战技能、持续通道技能
- **冷却管理**：统一维护玩家所有技能的冷却计时

### 4.5 EnergySystem（修炼能量系统）
- **职责**：玩家四属性能量管理、修炼等级计算、升级事件派发
- **核心数据**：
  ```gdscript
  # 四属性当前修为
  var flame_exp: float = 0.0
  var life_exp: float = 0.0
  var frost_exp: float = 0.0
  var shadow_exp: float = 0.0
  
  # 四属性境界等级
  var flame_level: int = 0
  var life_level: int = 0
  var frost_level: int = 0
  var shadow_level: int = 0
  ```
- **核心接口**：
  - `add_exp(attribute, amount)`：增加修为，自动检测升级
  - `absorb_crystal(crystal_item)`：吸收能量结晶
  - `get_level_up_threshold(attribute, level)`：获取升级阈值
  - `passive_absorb(delta, room_data)`：房间被动吸收计算
- **房间被动吸收**：每帧根据房间主属性浓度增加对应修为，速率 = 基础速率 × 房间浓度系数

### 4.6 RoomManager（房间管理器）
- **职责**：当前房间数据维护、房间能量状态、传送门逻辑、场景切换
- **RoomData 结构**：
  ```gdscript
  extends Resource
  class_name RoomData
  
  var id: String
  var name: String
  var scene_path: String
  var main_element: String
  var energy_concentration: float  # 0.0 ~ 1.0
  var level: int
  var unlocked: bool
  var connected_rooms: Array[String]  # 相邻可传送房间
  ```
- **核心接口**：
  - `enter_room(room_id)`：加载房间场景
  - `get_current_room() -> RoomData`
  - `add_room_energy(attribute, amount)`：增加房间能量

### 4.7 UIManager（UI 管理器）
- **职责**：UI 分层管理、界面打开关闭、数据绑定更新
- **UI 分层**（CanvasLayer）：
  - Layer 0：游戏世界 HUD（血条、能量条、技能栏）
  - Layer 1：浮动文字、伤害数字
  - Layer 2：弹窗面板（背包、角色、技能）
  - Layer 3：全屏菜单（设置、暂停）
- **更新方式**：监听 EventBus 事件更新 UI，不直接读取业务逻辑

### 4.8 InventorySystem（背包系统）
- **职责**：物品存储、物品使用、掉落拾取
- **ItemData 基类**：
  ```gdscript
  extends Resource
  class_name ItemData
  
  var id: String
  var name: String
  var icon: Texture2D
  var stackable: bool = true
  var item_type: String  # crystal / material / equipment / consumable
  ```
- **核心接口**：
  - `add_item(item_data, count)`
  - `remove_item(item_id, count)`
  - `use_item(item_id, slot_index)`

### 4.9 ForgeSystem（锻造系统）
- **职责**：锻造配方管理、装备打造、装备强化
- **RecipeData 结构**：材料列表 + 产出物品 + 消耗能量
- **核心接口**：
  - `can_forge(recipe_id) -> bool`
  - `forge(recipe_id)`：扣除材料和能量，产出物品
- **限制**：必须在有锻造台的房间才能使用

---

## 五、实体系统设计

### 5.1 EntityBase 实体基类
所有可交互实体的基类，统一接口：
```gdscript
extends CharacterBody2D
class_name EntityBase

@export var max_hp: float = 100.0
var hp: float
@export var defense: float = 0.0
@export var element: String = "flame"
var is_dead: bool = false

func take_damage(damage_info):
    # 子类可重写
    hp -= damage_info.damage
    if hp <= 0:
        die()

func die():
    is_dead = true
    EventBus.entity_died.emit(self)
    queue_free()
```

### 5.2 Player（玩家）
- 继承 EntityBase，实现 IDamageable
- 包含移动逻辑、输入处理、技能施放
- 鼠标朝向计算，攻击方向判定

### 5.3 EnemyBase（怪物基类）
- 继承 EntityBase
- 状态机 AI：巡逻 → 警戒 → 追击 → 攻击
- 死亡掉落：能量结晶、材料
- 掉落逻辑在 `die()` 中触发

---

## 六、数据驱动方案

所有数值配置使用 Godot `.tres` 资源文件，脚本定义结构，编辑器填值。

### 6.1 SkillData 技能数据
```gdscript
extends Resource
class_name SkillData

var id: String
var name: String
var element: String
var skill_type: String  # projectile / aoe / melee / buff
var damage: float = 0.0
var cooldown: float = 2.0
var cast_range: float = 200.0
var mana_cost: float = 0.0
var unlock_level: int = 1
var icon: Texture2D
var effect_scene: PackedScene  # 特效场景
var description: String
```

### 6.2 EnemyData 怪物数据
```gdscript
extends Resource
class_name EnemyData

var id: String
var name: String
var element: String
var max_hp: float
var attack: float
var defense: float
var move_speed: float
var scene: PackedScene
var drop_table: Array  # 掉落物品+概率
var exp_reward: float  # 死亡给的修为
```

### 6.3 数据加载方式
- 配置资源放在 `data/` 对应目录
- 管理器启动时预加载或按需加载
- 调整数值直接改 `.tres` 文件，无需改代码

---

## 七、场景与切换设计

### 7.1 房间场景结构

每个房间独立 `.tscn` 场景，统一结构：
```
RoomRoot
├── TileMap            # 瓦片地图
├── CollisionShape2D   # 墙体碰撞
├── SpawnPoints        # 怪物刷新点
├── Portals            # 传送门节点
└── RoomFunction       # 房间功能节点（锻造台等）
```

### 7.2 切换流程
1. 玩家进入传送门触发区域
2. 调用 `GameManager.change_room(target_room_id)`
3. 卸载当前房间场景，加载新场景
4. 玩家出生在新房间对应入口点
5. `RoomManager` 更新当前房间数据，派发 `room_loaded` 事件

---

## 八、关键技术实现要点

### 8.1 伤害判定
- 远程技能：Area2D 碰撞检测，命中触发伤害
- 近战技能：扇形/矩形范围判定，角度 + 距离双重校验
- 统一走 `BattleManager.deal_damage()` 入口

### 8.2 鼠标朝向
- 玩家每帧根据鼠标全局位置计算朝向角度
- `look_at(get_global_mouse_position())`
- 技能施放方向取玩家朝向向量

### 8.3 状态效果（Buff/DOT）
- BuffSystem 统一管理所有持续效果
- 每个 Buff 独立计时，到期自动移除
- Demo 优先实现灼烧 DOT，其他预留接口

---

## 九、网络扩展预留（架构层面）

当前单机开发，但架构上预留改造空间：
1. **事件总线层**：所有状态变更走事件，未来可在此层做网络同步
2. **逻辑表现分离**：数值计算逻辑独立，表现层只播动画特效
3. **数据层独立**：玩家状态、房间状态均为纯数据对象，易序列化
4. **输入抽象层**：玩家输入统一收集，未来可替换为服务端指令

---

## 十、开发里程碑

### 里程碑 1：核心战斗闭环（第 1~3 周）
- 项目骨架搭建 + 目录结构 + 管理器空壳
- 玩家移动 + 鼠标朝向 + 基础普攻
- TileMap 房间 + 墙体碰撞
- 怪物 AI + 基础追击
- IDamageable 接口 + 统一伤害系统
- 能量结晶掉落 + 拾取
- 房间切换

### 里程碑 2：系统成型（第 4~6 周）
- 修炼等级系统 + 被动吸收
- 技能系统框架 + 4 个赤焰战斗技能
- 技能栏 UI + HUD 基础界面
- 背包系统雏形
- 锻造系统 + 4 个生产技能
- 第三个据点房间 + 锻造台交互

### 里程碑 3：完善打磨（第 7~8 周，选做）
- 灼烧 DOT 状态效果
- 角色面板 / 背包面板 UI
- 存档系统
- 简单 NPC 交互
- 数值平衡调整

---

## 十一、技术亮点（简历可讲）

1. **模块化单例架构**：系统职责清晰，低耦合高内聚
2. **事件总线解耦**：模块间通过信号通信，扩展性强
3. **数据驱动设计**：所有数值配置化，无需改代码即可调平衡
4. **面向接口编程**：统一实体接口与伤害接口，新增类型零侵入
5. **策略模式技能系统**：基类抽象，子类实现，新增技能成本低
6. **分层架构预留网络扩展**：逻辑表现分离，未来改网游改造成本低
