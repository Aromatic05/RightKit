# **RightKit 项目技术计划书**

**版本:** 1.0
**作者:** Aromatic
**日期:** 2025年8月15日

## **1. 项目概述**

RightKit 是一款为 macOS 设计的右键菜单增强工具。它由一个主设置程序和一个 Finder 同步扩展（Finder Sync Extension）组成，旨在通过提供高度可定制的右键菜单，极大地提升用户在 Finder 中的文件操作效率。初期版本将专注于实现“新建文件”功能，并为后续的“剪切文件”、“复制路径”等高级功能搭建一个稳固且可拓展的框架。

## **2. 核心技术栈**

*   **语言:** Swift 6.x
*   **UI 框架:** SwiftUI (用于主设置程序，因其现代化的声明式语法，非常适合构建设置界面)
*   **开发环境:** Xcode 16+
*   **架构模式:** MVVM (Model-View-ViewModel)
*   **核心技术:**
    *   **Finder Sync Extension:** 用于向 Finder 注入菜单和图标。
    *   **App Groups:** 用于在主程序和扩展之间安全地共享数据。
    *   **Security-Scoped Bookmarks:** 用于持久化获取对用户指定文件夹（如模板目录）的访问权限。
    *   **`DistributedNotificationCenter`:** 用于在主程序修改配置后，实时通知扩展更新。

## **3. 架构设计**

项目包含两个主要目标（Target）:

1.  **RightKit (主程序):**
    *   **职责:** 提供图形化设置界面，让用户管理菜单结构、配置动作、设置模板文件夹路径，并引导用户开启扩展和获取必要权限。
    *   **产物:** `RightKit.app`

2.  **RightKitExtension (Finder Sync 扩展):**
    *   **职责:** 在后台运行，监听 Finder 的右键点击事件。动态读取共享的配置文件，构建并显示菜单。执行用户点击菜单项后关联的动作。
    *   **产物:** `RightKitExtension.appex` (内嵌在 `RightKit.app` 中)

**数据流与通信:**



1.  **配置写入:** 用户在主程序中修改设置 -> 主程序将配置写入 App Group 容器内的 `menu.json`。
2.  **通知发送:** 主程序通过 `DistributedNotificationCenter` 发送 “配置已更新” 的通知。
3.  **通知接收:** 扩展监听到通知，将自身标记为“需要刷新配置”。
4.  **菜单构建:** 用户右键点击 -> 扩展检查到“需要刷新”标记 -> 从 App Group 容器重新读取 `menu.json` -> 动态构建菜单。

## **4. 数据模型与存储**

1.  **配置文件 (`menu.json`):**
    *   **位置:** `[App Group Container]/Library/Application Support/RightKit/menu.json`
    *   **格式:** JSON
    *   **数据结构 (Swift 表示):**
        ```swift
        struct MenuItem: Codable {
            var name: String          // 菜单项名称
            var icon: String?         // 图标名称 (SF Symbols 或内置资源)
            var action: Action?       // 关联的动作
            var children: [MenuItem]? // 子菜单
        }

        struct Action: Codable {
            var type: ActionType      // 动作类型
            var parameter: String?    // 动作参数
        }

        enum ActionType: String, Codable {
            case createEmptyFile
            case createFileFromTemplate
            // 未来拓展...
            case copyFilePath
            case cutFile
            case runShellScript
        }
        ```

2.  **模板文件夹书签 (Security-Scoped Bookmark):**
    *   **位置:** 存储在 App Group 的 `UserDefaults` 中。主程序负责创建和存储，扩展负责读取和解析。

## **5. 开发里程碑 (逐步实现)**

我们将项目分为多个阶段，每个阶段都有明确的目标，便于专注和测试。

**阶段一：项目搭建与“Hello, World”** (预计用时: 1-2天)
1.  在 Xcode 中创建新项目，包含一个 macOS App Target (`RightKit`) 和一个 Finder Sync Extension Target (`RightKitExtension`)。
2.  配置项目的 Signing & Capabilities，为两个 Target 启用并设置同一个 App Group ID (例如 `group.com.aromatic.RightKit`)。
3.  在扩展代码中，实现 `menu(for:)` 方法，返回一个**硬编码**的 `NSMenuItem`，例如“Hello, RightKit!”。
4.  编译并运行项目，在“系统设置”>“隐私与安全性”>“扩展”中启用 RightKit 扩展。
5.  **目标:** 在 Finder 中右键，能够看到并点击“Hello, RightKit!”菜单项。这验证了项目基础结构和扩展注入是成功的。

**阶段二：动态菜单与数据共享** (预计用时: 2-3天)
1.  在主程序中，创建一个默认的 `menu.json` 文件作为资源。
2.  编写代码，在主程序启动时，将这个默认的 `menu.json` 复制到 App Group 的共享容器中。
3.  修改扩展代码，使其不再返回硬编码的菜单，而是：
    *   读取共享容器中的 `menu.json` 文件。
    *   解析 JSON 数据到 `[MenuItem]` 数据模型。
    *   根据数据模型，递归地动态构建多级 `NSMenu`。
4.  **目标:** 扩展能够根据 `menu.json` 的内容动态展示多级菜单。你可以手动修改共享容器中的 JSON 文件，并重新启动 Finder 来查看菜单变化。

**阶段三：实现核心功能 - 新建文件** (预计用时: 3-5天)
1.  **主程序:**
    *   创建一个简单的界面，允许用户通过 `NSOpenPanel` 选择模板文件夹。
    *   成功选择后，为该文件夹创建 Security-Scoped Bookmark，并将其数据存储到共享的 `UserDefaults`。
2.  **扩展:**
    *   实现 `ActionDispatcher`（动作分发器）。当菜单项被点击时，它会根据 `action.type` 调用相应的处理函数。
    *   实现 `handleCreateEmptyFile(parameter:)` 函数，用于在当前目录下创建一个指定后缀的空文件。
    *   实现 `handleCreateFileFromTemplate(parameter:)` 函数。该函数需要：
        *   从共享 `UserDefaults` 读取并解析书签，获得对模板文件夹的访问权限。
        *   根据参数（模板文件名），从模板文件夹复制文件到当前目录。
    *   修改动态菜单构建逻辑，使其能自动扫描模板文件夹，并为每个模板文件生成对应的“从模板新建”子菜单项。
3.  **目标:** “新建空白文件”和“从模板新建”功能完全可用。

**阶段四：构建完整的设置 UI 与实时通知** (预计用时: 5-7天)
1.  **主程序:**
    *   使用 SwiftUI 设计一个完整的设置界面，用户可以在其中可视化地添加、删除、编辑和拖拽排序菜单项。
    *   每次修改后，将新的菜单结构序列化为 JSON 并覆盖共享容器中的 `menu.json` 文件。
    *   在成功保存文件后，通过 `DistributedNotificationCenter` 发送更新通知。
2.  **扩展:**
    *   实现对 `DistributedNotificationCenter` 通知的监听。
    *   接收到通知后，刷新配置，确保下次用户右键时能看到最新的菜单。
3.  **目标:** 用户可以通过图形界面完全自定义右键菜单，并且更改能够实时生效，无需重启 Finder。

**阶段五：功能拓展与完善** (长期)
1.  实现“复制路径”、“剪切/粘贴文件”等新的 Action 类型。
2.  支持自定义菜单图标。
3.  完善错误处理（如 JSON 解析失败、模板文件夹不存在等）。
4.  进行本地化，支持多语言。
5.  设计并添加应用图标。

---

遵循这份计划书，你将能够系统性地构建你的 RightKit 项目，从最核心的功能验证开始，逐步添加功能和完善用户体验，最终打造出一款功能强大且稳定的产品。祝你开发顺利

