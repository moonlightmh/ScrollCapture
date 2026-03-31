# ScrollCapture - macOS 滚动截图工具设计文档

**日期**: 2026-03-30
**平台**: macOS 12.0+ (Monterey)
**技术栈**: Swift/SwiftUI + OpenCV 4.x C++

---

## 概述

ScrollCapture 是一个 macOS 菜单栏应用，用于截取有滚动内容的窗口的长图。用户通过手动滚动并按快捷键触发截图，工具自动使用智能拼接算法生成完整的长图。

---

## 需求摘要

| 需求项 | 决定 |
|--------|------|
| 使用场景 | 任何有滚动条的窗口（通用） |
| 交互方式 | 手动滚动 + 快捷键触发截图 |
| 截图触发 | 按快捷键 `Cmd+Shift+S` 触发截图 |
| 拼接方式 | 智能拼接（OpenCV 模板匹配） |
| 技术栈 | Swift/SwiftUI 原生应用 |
| 应用形态 | 轻量 GUI（菜单栏应用） |
| OpenCV 集成 | 嵌入 C++ 库编译到项目中 |

---

## 第一节：整体架构

```
┌─────────────────────────────────────────────────────┐
│                   ScrollCaptureApp                   │
│                    (Swift/SwiftUI)                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐    ┌─────────────┐                │
│  │ AppDelegate │───▶│ StatusItem  │ (菜单栏图标)   │
│  │ (入口)      │    │ Controller  │                │
│  └─────────────┘    └─────────────┘                │
│                           │                         │
│                           ▼                         │
│  ┌─────────────┐    ┌─────────────┐                │
│  │  HotKey     │◀───│ Capture     │                │
│  │  Manager    │    │ Manager     │ (截图流程控制) │
│  └─────────────┘    └─────────────┘                │
│                           │                         │
│                           ▼                         │
│  ┌─────────────────────────────────┐               │
│  │        StitchEngine             │               │
│  │    (Swift + OpenCV C++)         │               │
│  │  ├─ StitchEngine.swift          │               │
│  │  ├─ StitchEngineBridge.h        │               │
│  │  └─ StitchEngineImpl.cpp        │               │
│  │  - 图像拼接                      │               │
│  │  - 模板匹配算法                  │               │
│  └─────────────────────────────────┘               │
│                           │                         │
│                           ▼                         │
│  ┌─────────────────────────────────┐               │
│  │        ExportManager            │               │
│  │    - 导出 PNG/JPG               │               │
│  │    - 保存到指定路径              │               │
│  └─────────────────────────────────┘               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**核心模块职责：**

| 模块 | 职责 |
|------|------|
| AppDelegate | 应用入口，初始化各组件 |
| StatusItemController | 菜单栏图标管理，显示状态/菜单 |
| HotKeyManager | 注册/监听全局快捷键 |
| CaptureManager | 截图流程控制（选区、截图、拼接触发） |
| StitchEngine | OpenCV 图像拼接算法 |
| ExportManager | 导出最终长图 |

---

## 第二节：用户交互流程

### 交互流程图

```
用户操作                    应用响应                    UI状态
──────────────────────────────────────────────────────────────

1. 启动应用              → 初始化各模块             → 菜单栏图标显示
                                                    → 默认状态：待机

2. 点击菜单栏图标        → 弹出下拉菜单             → 菜单选项：
                         │                         │ • 开始截图
                         │                         │ • 设置
                         │                         │ • 退出

3. 选择"开始截图"        → 进入区域选择模式         → 屏幕显示选区框
                         → 用户拖拽选择目标区域     → 选区框显示尺寸信息
                         → 菜单栏图标：选择区域中...

4. 松开鼠标确认选区      → 记录区域坐标             → 菜单栏图标：已截图 0 张
                         → 注册快捷键监听           → 浮动提示：
                         → 准备截图模式             │ "滚动后按 Cmd+Shift+S 截图
                         │                         │  按 Esc 取消"
                         │                         │ 显示 2 秒后消失

5. 用户滚动，按快捷键    → 截取选区内容             → 菜单栏图标：已截图 N 张
                         → 调用 StitchEngine 拼接   → 状态更新

6. 点击"结束截图"        → 完成拼接                 → 弹出 NSSavePanel
                         → 准备导出                 │ 默认格式：PNG
                         │                         │ 默认路径：上次导出位置
                         │                         │ 或 ~/Downloads

7. 用户选择保存位置      → 导出最终图片             → 显示成功提示（菜单栏）
                         → 清理临时文件             → "已保存到 xxx"
                         → 菜单栏图标：待机         → 3 秒后恢复正常
```

### 快捷键设计

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Cmd+Shift+S` | 触发截图 | 默认，可自定义 |
| `Esc` | 取消当前流程 | 退出截图模式，清理临时文件 |
| `Cmd+Shift+E` | 结束并导出 | 可选，快速完成 |

### 快捷键冲突处理

```
注册快捷键失败
    │
    ├── 尝试备用快捷键 1: Cmd+Option+S
    │       │
    │       ├── 成功 → 使用备用键，菜单栏提示"快捷键已更改"
    │       │
    │       └── 失败 → 尝试备用快捷键 2: Cmd+Ctrl+S
    │               │
    │               ├── 成功 → 同上
    │               │
    │               └── 失败 → 提示用户手动设置
    │                       "默认快捷键被占用，请在设置中自定义"
```

---

## 第三节：智能拼接算法设计

### 拼接流程

```
截图序列：[S1, S2, S3, ... Sn]

拼接流程：
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│   S1     │───▶│   S2     │───▶│   S3     │───▶│   Sn     │
│ (基准)   │    │          │    │          │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
     │              │              │              │
     └──────┬───────┘              │              │
            │                      │              │
            ▼                      │              │
     ┌──────────────┐              │              │
     │ 模板匹配     │              │              │
     │ 找重叠区域   │              │              │
     └──────────────┘              │              │
            │                      │              │
            ▼                      │              │
     ┌──────────────┐──────┬───────┘              │
     │  拼接 S1+S2  │      │                      │
     │  = Result1   │      │                      │
     └──────────────┘      │                      │
            │              ▼                      │
            │       ┌──────────────┐              │
            │       │ 模板匹配     │              │
            │       │ 找重叠区域   │              │
            │       └──────────────┘              │
            │              │                      │
            │              ▼                      │
            │       ┌──────────────┐              │
            └──────▶│ 拼接 Result1 │              │
                    │  + S3        │              │
                    │  = Result2   │              │
                    └──────────────┘              │
                           │              (循环...)
                           ▼
                    ┌──────────────┐
                    │ 最终长图     │
                    └──────────────┘
```

### 算法参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 模板高度 | 100 px | 从结果图底部提取的模板高度 |
| 搜索范围 | 模板高度 × 2 | 在新截图顶部搜索的区域范围 |
| 匹配方法 | `TM_CCOEFF_NORMED` | OpenCV 模板匹配方法 |
| 匹配阈值 | 0.85 | 匹配置信度阈值，低于此值判定为匹配失败 |
| 最大重叠 | 模板高度 × 1.5 | 防止异常匹配值 |

### 算法步骤（每张新截图）

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 取当前结果图底部 N 行 | 作为模板（N = 100px 或 learnedOverlap） |
| 2 | 在新截图顶部 200px 区域搜索模板 | 使用 OpenCV `matchTemplate` |
| 3 | 计算匹配置信度 | 若 < 0.85，判定匹配失败 |
| 4 | 找到最佳匹配位置 | 得到实际重叠像素数 |
| 5 | 去除重叠部分，拼接新截图 | 只添加新内容区域 |
| 6 | 更新 learnedOverlap | 记录实际重叠值，用于下次估算 |
| 7 | 更新结果图 | 供下一次拼接使用 |

### StitchEngine 接口定义

```swift
struct StitchResult {
    let image: CGImage?           // 拼接结果图像
    let confidence: Double        // 匹配置信度 (0.0 - 1.0)
    let overlapPixels: Int        // 实际重叠像素数
    let success: Bool             // 是否成功
    let error: StitchError?       // 错误信息（如有）
}

enum StitchError {
    case noOverlap                 // 没有找到重叠区域
    case lowConfidence             // 匹配置信度过低
    case imageTooLarge             // 图像尺寸超出限制
    case memoryExceeded            // 内存超出限制
}

class StitchEngine {
    var overlapEstimate: Int = 100      // 初始重叠估算值
    var learnedOverlap: Int?            // 学习值（历史平均值）
    var maxResultHeight: Int = 50000    // 最大结果图高度（px）

    func stitch(baseImage: CGImage, newImage: CGImage) -> StitchResult
    func reset()                         // 清理状态，准备新会话
}
```

### 边界情况处理

| 情况 | 处理方式 | 用户提示 |
|------|----------|----------|
| 没有重叠（滚动过多） | 保留空白区域拼接 | "检测到断层，拼接可能不完整" |
| 匹配失败（滚动过快/内容变化） | 使用 learnedOverlap 或默认值估算 | "检测到拼接困难，使用估算值拼接" |
| 结果图超长（> 50000px） | 提示用户停止并导出当前结果 | "图片过长，建议导出当前结果后继续" |
| 内存不足 | 释放旧截图缓存，继续拼接 | 无提示（后台处理） |

### 边界情况实现细节

```swift
// 空白区域定义
let blankRegionColor: NSColor = .clear    // 透明，不填充颜色
let blankRegionHeight: Int = 50           // 空白区域高度（px）

// 分段处理逻辑
func checkResultHeight(_ height: Int) -> Bool {
    return height <= maxResultHeight  // 50000px
}

// 超长处理：提示用户导出当前结果
func handleTooLarge() {
    // 1. 弹出确认框
    // "当前截图已超过 50000px，建议先导出当前结果。"
    // [继续截图（可能影响性能）]  [结束并导出]
    //
    // 2. 用户选择继续 → 设置警告标志，继续截图
    // 3. 用户选择导出 → 结束会话，导出当前结果
}
```

### 滚动方向处理

| 滚动方向 | 处理方式 |
|----------|----------|
| 向下滚动（正常） | 正常拼接，新内容追加到底部 |
| 向上滚动（回退） | 检测到重叠过大时，忽略该截图（已在结果图中） |
| 来回滚动 | 只向下追加新内容，向上滚动产生的截图被忽略 |

---

## 第四节：数据存储与状态管理

### 模块关系图

```
┌─────────────────────────────────────────────────────┐
│                    AppState                          │
│               (ObservableObject)                     │
│                  (全局单例)                          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  @Published captureState: CaptureState              │
│  @Published screenshotCount: Int = 0                │
│  @Published lastExportPath: String?                 │
│                                                     │
│  持有:                                               │
│  └─ currentSession: CaptureSession?                 │
│     (仅在 capturing 状态时存在)                      │
│                                                     │
└─────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│                CaptureSession                        │
│               (临时截图数据)                          │
│              (每次截图会话新建)                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  var selectedRect: CGRect?          // 选区坐标     │
│  var screenshots: [CGImage]         // 截图序列     │
│  │                  // 只保留最近 3 张              │
│  var stitchedResult: CGImage?       // 拼接结果     │
│  var overlapHistory: [Int]          // 重叠历史     │
│  var tempFiles: [URL]               // 临时文件     │
│                                                     │
│  func addScreenshot(_ image: CGImage)               │
│  │  → 存入 screenshots                              │
│  │  → 若 screenshots.count > 3，转存到临时文件     │
│  │  → 触发拼接                                      │
│                                                     │
│  func clear()                                        │
│  │  → 清空 screenshots                              │
│  │  → 删除临时文件                                  │
│  │  → 清空 overlapHistory                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### CaptureState (Enum)

```swift
enum CaptureState {
    case idle              // 待机
    case selectingArea     // 选择区域
    case capturing         // 截图进行中
    case exporting         // 导出中
    case error(String)     // 错误状态（带消息）
}
```

### 持久化存储 (UserDefaults)

| 数据 | Key | 默认值 | 说明 |
|------|-----|--------|------|
| 截图快捷键 | `hotkeyScreenshot` | `Cmd+Shift+S` | 可自定义 |
| 结束快捷键 | `hotkeyEnd` | `Cmd+Shift+E` | 可自定义 |
| 默认导出格式 | `exportFormat` | `PNG` | PNG 或 JPG |
| JPG 质量 | `jpgQuality` | `0.9` | 0.0 - 1.0 |
| 最近导出路径 | `lastExportPath` | `~/Downloads` | 方便下次选择 |
| 重叠学习值 | `learnedOverlap` | `100` | 根据历史优化 |
| 模板高度 | `templateHeight` | `100` | 可调整 |
| 匹配阈值 | `matchThreshold` | `0.85` | 可调整 |

### 临时文件策略

| 场景 | 操作 |
|------|------|
| 截图时 | 先存入内存（screenshots 数组） |
| 内存超限（> 3 张） | 转存到 `~/Library/Caches/ScrollCapture/temp/{sessionID}/` |
| 拼接完成 | 删除对应的临时文件 |
| 会话结束（成功） | 清空整个临时目录 |
| 会话取消 | 清空整个临时目录 |
| 应用退出 | 清空整个临时目录 |

---

## 第五节：错误处理与用户提示

| 错误类型 | 处理策略 | 用户提示 |
|----------|----------|----------|
| 选区无效（宽度/高度为0） | 阻止进入截图模式 | "请选择有效的截图区域" |
| 选区超出屏幕边界 | 自动调整到屏幕范围内 | 无提示 |
| 快捷键注册失败 | 尝试备用快捷键，最终提示设置 | "默认快捷键被占用，请在设置中自定义" |
| 截图权限缺失 | 引导用户开启权限 | "请在系统设置 > Privacy > 屏幕录制 中开启 ScrollCapture" |
| 模板匹配失败 | 回退到估算值拼接 | "检测到拼接困难，使用估算值拼接" |
| 没有重叠区域 | 保留空白区域拼接 | "检测到断层，拼接可能不完整" |
| 内存不足 | 释放旧截图缓存 | 无提示（后台处理） |
| 结果图过长 | 分段处理或提示 | "图片过长，建议分段截取" |
| 导出失败 | 尝试其他路径 | "导出失败，请选择其他保存位置" |
| 磁盘空间不足 | 提示用户清理 | "磁盘空间不足，无法保存" |

### 权限检查流程（启动时）

```
App 启动
    │
    ▼
检查屏幕录制权限
    │
    ├── 有权限 → 正常运行
    │
    └── 无权限 → 弹出提示框
                 │
                 ▼
             ┌─────────────────────────────────┐
             │ ScrollCapture 需要屏幕录制权限   │
             │ 才能截取屏幕内容。               │
             │                                 │
             │ [打开系统设置]    [稍后设置]     │
             └─────────────────────────────────┘
                 │
                 ▼
             点击"打开系统设置"
             → 跳转到 System Settings > Privacy > Screen Recording
```

---

## 第六节：文件结构

```
ScrollCapture/
├── ScrollCapture.xcodeproj
├── ScrollCapture/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   ├── ScrollCaptureApp.swift
│   │   └── Constants.swift
│   ├── Controllers/
│   │   ├── StatusItemController.swift
│   │   ├── CaptureManager.swift
│   │   ├── HotKeyManager.swift
│   │   └── ExportManager.swift
│   ├── Models/
│   │   ├── AppState.swift
│   │   ├── CaptureState.swift
│   │   ├── CaptureSession.swift
│   │   └── StitchResult.swift
│   ├── Views/
│   │   ├── SelectionOverlayView.swift     // 选区框视图
│   │   ├── SettingsWindow.swift           // 设置窗口
│   │   └── ToastView.swift                 // 浮动提示
│   ├── Engine/
│   │   ├── StitchEngine.swift             // Swift 接口层
│   │   ├── StitchEngineBridge.h           // ObjC 桥接头文件
│   │   ├── StitchEngineBridge.mm          // ObjC++ 实现
│   │   └── StitchEngineImpl.cpp           // C++ OpenCV 实现
│   ├── Utils/
│   │   ├── PermissionChecker.swift
│   │   ├── TempFileManager.swift
│   │   └── ImageConverter.swift           // CGImage <-> cv::Mat 转换
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Localizable.strings            // 本地化字符串
│   ├── Vendor/
│   │   └── opencv2.framework/             // OpenCV 预编译库
│   └── Info.plist
├── ScrollCaptureTests/
│   ├── StitchEngineTests.swift
│   ├── CaptureManagerTests.swift
│   └── ImageConverterTests.swift
├── docs/
│   └── superpowers/
│   │       └── specs/
│   │               └── 2026-03-30-scrollcapture-design.md
└── README.md
```

---

## 第七节：OpenCV 集成方案

### OpenCV 版本

- **版本**: OpenCV 4.8.x
- **获取方式**: 使用预编译 `opencv2.framework`
- **下载地址**: https://github.com/opencv/opencv/releases

### 集成步骤

1. 下载 `opencv2.framework`
2. 放入 `Vendor/` 目录
3. 在 Xcode 项目设置中：
   - Link Binary With Libraries → 添加 `opencv2.framework`
   - Framework Search Paths → 添加 `$(PROJECT_DIR)/Vendor`
4. 创建 ObjC++ 桥接文件

### Swift-C++ 桥接架构

```
┌─────────────────────────────────────────────────────┐
│                    Swift 层                          │
│                                                     │
│  StitchEngine.swift                                 │
│  ├─ 公开 API                                        │
│  ├─ 接收 CGImage                                    │
│  └─ 返回 StitchResult                               │
│                                                     │
└─────────────────────────────────────────────────────┘
                         │
                         ▼ (调用 ObjC 方法)
┌─────────────────────────────────────────────────────┐
│                   ObjC++ 桥接层                      │
│                                                     │
│  StitchEngineBridge.h / .mm                         │
│  ├─ 接收 CGImageRef                                 │
│  ├─ 转换为 cv::Mat                                  │
│  └─ 返回 CGImageRef                                 │
│                                                     │
│  关键职责：                                          │
│  ├─ 内存管理（CGImageRef 引用计数）                 │
│  └─ 数据转换（CGImage <-> cv::Mat）                 │
│                                                     │
└─────────────────────────────────────────────────────┘
                         │
                         ▼ (调用 C++ 函数)
┌─────────────────────────────────────────────────────┐
│                    C++ 层                            │
│                                                     │
│  StitchEngineImpl.cpp                               │
│  ├─ 模板匹配 (matchTemplate)                        │
│  ├─ 图像拼接                                        │
│  └─ 返回 cv::Mat                                    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 内存管理策略

| 数据类型 | 所有权 | 管理方式 |
|----------|--------|----------|
| Swift → ObjC++ 的 CGImageRef | Swift 拥有 | 传递时不增加引用计数，ObjC++ 只借用 |
| ObjC++ → C++ 的 cv::Mat | ObjC++ 创建 | 从 CGImageRef 复制数据到 Mat |
| C++ → ObjC++ 的 cv::Mat | C++ 返回 | ObjC++ 接收后负责销毁 |
| ObjC++ → Swift 的 CGImageRef | ObjC++ 创建 | 使用 `CGImageCreate`，Swift 负责释放 |

```objc
// StitchEngineBridge.mm 示例

- (StitchResultBridge *)stitchImages:(CGImageRef)baseRef
                             withNew:(CGImageRef)newRef {
    // 1. 转换 CGImageRef -> cv::Mat（复制数据）
    cv::Mat baseMat = [self cvMatFromCGImage:baseRef];
    cv::Mat newMat = [self cvMatFromCGImage:newRef];

    // 2. 调用 C++ 实现
    StitchResultCpp result = matchAndStitch(baseMat, newMat);

    // 3. 转换 cv::Mat -> CGImageRef（创建新对象）
    CGImageRef resultRef = [self cgImageFromCvMat:result.image];

    // 4. 封装结果
    StitchResultBridge *bridgeResult = [[StitchResultBridge alloc] init];
    bridgeResult.imageRef = resultRef;  // Swift 负责释放
    bridgeResult.confidence = result.confidence;
    bridgeResult.overlapPixels = result.overlapPixels;
    bridgeResult.success = result.success;

    return bridgeResult;
}

// CGImageRef -> cv::Mat（复制数据，不共享）
- (cv::Mat)cvMatFromCGImage:(CGImageRef)image {
    // 创建临时 CGContext
    // 复制像素数据到 cv::Mat
    // 返回 Mat（数据独立，可安全使用）
}

// cv::Mat -> CGImageRef（创建新 CGImage）
- (CGImageRef)cgImageFromCvMat:(cv::Mat)mat {
    // 创建 CGDataProvider
    // 创建 CGImage
    // 返回 CGImageRef（调用者负责释放）
}
```

---

## 第八节：设置界面设计

### 入口

- 菜单栏下拉菜单 → "设置"
- 或使用 `Cmd+,` 快捷键（macOS 标准）

### 设置窗口布局

```
┌─────────────────────────────────────────────────────┐
│                    设置                              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  快捷键                                              │
│  ┌─────────────────────────────────────────────┐   │
│  │ 截图触发：    [Cmd+Shift+S    ] [修改]      │   │
│  │ 结束导出：    [Cmd+Shift+E    ] [修改]      │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  导出设置                                            │
│  ┌─────────────────────────────────────────────┐   │
│  │ 默认格式：    [PNG ▼]                        │   │
│  │ JPG 质量：    [██████████░░] 90%            │   │
│  │ 默认路径：    ~/Downloads           [选择]  │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  拼接设置                                            │
│  ┌─────────────────────────────────────────────┐   │
│  │ 模板高度：    [100] px                       │   │
│  │ 匹配阈值：    [0.85]                         │   │
│  │ 最大长度：    [50000] px                     │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│                              [恢复默认]    [关闭]   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 设置项说明

| 设置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| 截图快捷键 | KeyRecorder | Cmd+Shift+S | 触发截图的快捷键 |
| 结束快捷键 | KeyRecorder | Cmd+Shift+E | 结束并导出的快捷键 |
| 默认格式 | Dropdown | PNG | PNG 或 JPG |
| JPG 质量 | Slider | 90% | 50% - 100% |
| 默认路径 | PathPicker | ~/Downloads | 导出默认目录 |
| 模板高度 | NumberField | 100 | 模板匹配的高度 |
| 匹配阈值 | NumberField | 0.85 | 0.5 - 0.99 |
| 最大长度 | NumberField | 50000 | 10000 - 100000 |

### 快捷键冲突检测

设置界面快捷键设置项需包含实时冲突检测：

```
┌─────────────────────────────────────────────────────┐
│ 截图触发：    [Cmd+Shift+S    ] [修改]             │
│              ✓ 当前快捷键可用                       │
│              或                                      │
│              ⚠ 此快捷键已被其他应用占用             │
│                建议选择其他组合                      │
└─────────────────────────────────────────────────────┘
```

**实现逻辑**：
1. 用户点击"修改"按钮 → 进入快捷键录制模式
2. 用户按下新组合键 → 实时检测是否被占用
3. 若被占用 → 显示警告提示，但允许用户继续选择（用户可能想覆盖）
4. 若可用 → 显示绿色确认图标
5. 用户确认 → 保存新快捷键，重新注册全局监听

---

## 第九节：测试策略

### 单元测试

| 测试类 | 测试内容 | 覆盖率目标 |
|--------|----------|------------|
| StitchEngineTests | 模板匹配算法、边界情况 | > 90% |
| ImageConverterTests | CGImage <-> cv::Mat 转换 | > 95% |
| CaptureSessionTests | 截图添加、清理、临时文件 | > 90% |
| AppStateTests | 状态切换、持久化 | > 85% |

### 关键测试用例

```swift
// StitchEngineTests.swift

func testNormalStitch() {
    // 正常拼接：两张有重叠的截图
    // 验证：confidence > 0.85, overlapPixels 正确
}

func testNoOverlap() {
    // 无重叠：两张完全不重叠的截图
    // 验证：返回 StitchError.noOverlap
}

func testScrollUp() {
    // 向上滚动：新截图完全在结果图中
    // 验证：返回 StitchError.alreadyIncluded（或类似）
}

func testLowConfidence() {
    // 低置信度：内容变化或滚动过快
    // 验证：返回 StitchError.lowConfidence
}

func testImageTooLarge() {
    // 图像过长：模拟超长结果图
    // 验证：返回 StitchError.imageTooLarge
}

func testMemoryExceeded() {
    // 内存超限：模拟内存压力
    // 验证：正确处理，不崩溃
}

// ImageConverterTests.swift

func testCGImageToCvMatRoundTrip() {
    // CGImage -> cv::Mat -> CGImage
    // 验证：像素数据无损
}

func testDifferentColorSpaces() {
    // 不同颜色空间：RGBA, RGB, Grayscale
    // 验证：正确转换
}
```

### 集成测试

| 测试场景 | 测试内容 |
|----------|----------|
| 完整截图流程 | 选区 → 截图 → 拼接 → 导出 |
| 多次截图会话 | 连续多次截图会话，验证状态清理 |
| 快捷键响应 | 快捷键注册、触发、冲突处理 |
| 权限流程 | 权限缺失时的引导流程 |

### 性能测试

| 测试项 | 目标 |
|--------|------|
| 单次截图响应时间 | < 100ms |
| 单次拼接时间（标准场景） | < 200ms |
| 10 张截图拼接总时间 | < 2s |
| 内存峰值（10 张截图） | < 200MB |
| 50 张截图内存峰值 | < 500MB |

---

## 第十节：选区选择 UI

### 选区框行为

```
用户操作                    UI响应
───────────────────────────────────────

1. 点击"开始截图"       → 屏幕半透明遮罩层
                         → 鼠标变为十字光标
                         → 显示提示："拖拽选择截图区域"

2. 按下鼠标左键         → 显示选区框（虚线边框）
                         → 边框角显示尺寸信息
                         │ 例如：1920 × 800

3. 拖拽鼠标             → 选区框实时调整大小
                         → 尺寸信息实时更新

4. 松开鼠标             → 确认选区
                         → 选区框变为实线（高亮）
                         → 显示确认按钮：
                         │ [重新选择]  [确认开始]
                         │ 或直接开始截图（更简洁）

5. 按 Esc              → 取消选区选择
                         → 返回待机状态

6. 按 Enter            → 确认选区
                         → 开始截图模式
```

### 选区框样式

| 元素 | 样式 |
|------|------|
| 遮罩层 | 黑色半透明（alpha = 0.3） |
| 选区框 | 白色虚线边框，2px |
| 尺寸标签 | 白色文字，黑色半透明背景，位于左上角 |
| 确认按钮 | macOS 标准按钮样式，悬浮在选区右下角 |

---

## 第十一节：导出流程

### NSSavePanel 配置

```swift
let savePanel = NSSavePanel()
savePanel.title = "保存长图"
savePanel.nameFieldStringValue = "长截图_\(timestamp)"
savePanel.allowedContentTypes = [.png, .jpeg]
savePanel.directoryURL = URL(fileURLWithPath: lastExportPath ?? "~/Downloads")
savePanel.isExtensionHidden = false
savePanel.canCreateDirectories = true

// 添加格式选择 accessory view
let formatPopup = NSPopUpButton()
formatPopup.addItems(withTitles: ["PNG", "JPG"])
savePanel.accessoryView = formatPopup

savePanel.begin { response in
    if response == .OK {
        let url = savePanel.url!
        // 导出图片
    }
}
```

### 导出成功提示

- 菜单栏图标旁边显示临时提示
- 内容："已保存到 ~/Downloads/长截图_xxx.png"
- 显示 3 秒后自动消失
- 可点击打开文件位置

---

## 第十二节：后续扩展（可选）

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 自动滚动模式 | P2 | 工具自动控制滚动并截图 |
| 历史记录管理 | P3 | 查看和管理已导出的长图 |
| 云同步导出 | P3 | 直接上传到云存储 |
| 自定义水印 | P4 | 导出时添加时间戳水印 |
| 多显示器支持 | P3 | 支持跨显示器选区 |

---

## 成功标准

1. **核心功能完整**：能截取任意窗口的滚动内容并正确拼接
2. **拼接准确率 > 95%**：智能拼接算法在各种场景下准确匹配
3. **内存高效**：长图拼接不导致内存溢出，支持 50+ 张截图
4. **用户体验流畅**：菜单栏状态清晰，快捷键响应及时
5. **权限处理完善**：正确引导用户开启必要权限

---

## 开发里程碑

| 阶段 | 内容 | 预计时间 |
|------|------|----------|
| Phase 1 | 项目骨架 + 菜单栏基础功能 | 1-2 天 |
| Phase 2 | 区域选择 UI + 截图功能 | 2-3 天 |
| Phase 3 | OpenCV 集成 + 拼接算法 | 3-4 天 |
| Phase 4 | 设置界面 + 导出功能 | 2-3 天 |
| Phase 5 | 测试 + 优化 + 打包 | 2-3 天 |
| **总计** | | **10-15 天** |

---

## 技术依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| macOS | 12.0+ | 运行平台 |
| Swift | 5.7+ | 主要开发语言 |
| SwiftUI | 3.0+ | UI 框架 |
| OpenCV | 4.8.x | 图像处理/模板匹配 |
| Carbon | - | 全局快捷键监听（系统框架） |