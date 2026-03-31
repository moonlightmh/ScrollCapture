# ScrollCapture

macOS 滚动截图工具 - 支持任意窗口的长图截取

## 功能

- 🖼️ **通用截图**: 截取任何有滚动条的窗口内容
- 🔗 **智能拼接**: 使用 OpenCV 模板匹配算法自动拼接
- ⌨️ **快捷键操作**: 手动滚动后按键触发，精准控制
- 💾 **多格式导出**: 支持 PNG 和 JPG 格式
- ⚙️ **可配置参数**: 模板高度、匹配阈值等可调整

## 系统要求

- macOS 12.0+ (Monterey)
- 屏幕录制权限

## 安装

### 从源码构建

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/ScrollCapture.git
cd ScrollCapture
```

2. **安装 CocoaPods 依赖**
```bash
pod install
```

3. **在 Xcode 中创建项目**

由于无法通过命令行创建完整的 Xcode 项目，请在 Xcode 中手动创建：

- 打开 Xcode
- File → New → Project
- 选择 macOS → App
- Product Name: `ScrollCapture`
- Interface: SwiftUI
- Language: Swift
- 保存到现有目录（覆盖）

4. **配置项目**

将以下文件添加到 Xcode 项目：
- `ScrollCapture/App/` - 应用入口
- `ScrollCapture/Controllers/` - 控制器
- `ScrollCapture/Models/` - 数据模型
- `ScrollCapture/Views/` - SwiftUI 视图
- `ScrollCapture/Engine/` - OpenCV 引擎
- `ScrollCapture/Utils/` - 工具类
- `ScrollCapture/Info.plist` - 配置文件

5. **配置 Bridging Header**

在 Build Settings 中设置：
- Objective-C Bridging Header: `ScrollCapture/ScrollCapture-Bridging-Header.h`

6. **构建运行**
```bash
# 使用 workspace（因为 CocoaPods）
open ScrollCapture.xcworkspace
```

## 使用方法

1. **启动应用**: 运行 ScrollCapture，菜单栏会显示图标
2. **开始截图**: 点击菜单栏图标 → "开始截图"
3. **选择区域**: 拖拽选择要截图的区域
4. **滚动截图**:
   - 滚动内容
   - 按 `Cmd+Shift+S` 触发截图
   - 重复直到截取完成
5. **导出**: 点击"结束截图" → 选择保存位置

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd+Shift+S` | 截图 (需配置) |
| `Esc` | 取消当前操作 |
| `Cmd+,` | 打开设置 |

## 项目结构

```
ScrollCapture/
├── App/           # 应用入口
├── Controllers/   # 控制器
├── Models/        # 数据模型
├── Views/         # SwiftUI 视图
├── Engine/        # OpenCV 拼接引擎
├── Utils/         # 工具类
└── Resources/     # 资源文件
```

## 技术栈

- Swift 5.7+ / SwiftUI
- OpenCV 4.8.x (C++)
- ScreenCaptureKit

## 许可证

MIT License