//
//  MenuEditorView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

struct MenuEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedItemId: UUID?
    @State private var expandedItems: Set<UUID> = []
    
    // 递归查找选中项
    private func findMenuItem(by id: UUID?, in items: [MenuItem]) -> MenuItem? {
        guard let id = id else { return nil }
        for item in items {
            if item.id == id { return item }
            if let children = item.children, let found = findMenuItem(by: id, in: children) {
                return found
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("右键菜单结构")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("添加子项") {
                        print("[DEBUG] 添加子项按钮点击, 当前选中操作: \(String(describing: viewModel.selectedActionType))")
                        DispatchQueue.main.async {
                            if let actionType = viewModel.selectedActionType {
                                print("[DEBUG] 创建新菜单项, 类型: \(actionType)")
                                let newItem = MenuItem(
                                    name: actionTypeDisplayName(actionType),
                                    icon: actionTypeIcon(actionType),
                                    action: Action(type: actionType, parameter: nil),
                                    children: nil
                                )
                                if let parent = findMenuItem(by: selectedItemId, in: viewModel.menuItems) {
                                    print("[DEBUG] 添加到父菜单: \(parent.name)")
                                    viewModel.addMenuItem(newItem, to: parent)
                                    expandedItems.insert(parent.id)
                                } else {
                                    print("[DEBUG] 添加到根菜单")
                                    viewModel.addMenuItem(newItem)
                                }
                            } else {
                                print("[DEBUG] 未选中操作类型, 添加默认子菜单")
                                viewModel.addSubmenu()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("添加分隔线") {
                        DispatchQueue.main.async {
                            viewModel.addSeparator()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            
            Divider()
            
            // 菜单树视图
            if viewModel.menuItems.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("菜单为空")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("从左侧模板库添加项目或点击上方按钮")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.menuItems) { item in
                            MenuItemTreeView(
                                item: item,
                                level: 0,
                                selectedItemId: $selectedItemId,
                                expandedItems: $expandedItems
                            )
                            .environmentObject(viewModel)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 底部详情编辑区域
            if let selectedItem = findMenuItem(by: selectedItemId, in: viewModel.menuItems) {
                Divider()
                MenuItemDetailEditor(item: selectedItem)
                    .environmentObject(viewModel)
                    .padding(16)
                    .background(.regularMaterial)
            }
        }
        .dropDestination(for: TemplateInfo.self) { templates, location in
            // Handle dropping templates from the template library
            for template in templates {
                viewModel.createMenuItemFromTemplate(template)
            }
            return true
        }
    }
}

struct MenuItemTreeView: View {
    let item: MenuItem
    let level: Int
    @Binding var selectedItemId: UUID?
    @Binding var expandedItems: Set<UUID>
    @EnvironmentObject var viewModel: AppViewModel
    @State private var isHovered = false
    
    private var isExpanded: Bool {
        expandedItems.contains(item.id)
    }
    
    private var hasChildren: Bool {
        item.children?.isEmpty == false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 当前项目行
            HStack(spacing: 8) {
                // 缩进
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20)
                    }
                }
                
                // 展开/收起按钮
                if hasChildren {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isExpanded {
                                expandedItems.remove(item.id)
                            } else {
                                expandedItems.insert(item.id)
                            }
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 16, height: 16)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16, height: 16)
                }
                
                // 图标
                Image(systemName: item.icon ?? "questionmark")
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                // 名称
                Text(item.name)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(item.isSeparator ? .secondary : .primary)
                
                Spacer()
                
                // 类型标识
                Text(item.typeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                // 悬停时的操作按钮
                if isHovered {
                    HStack(spacing: 4) {
                        if hasChildren {
                            Button {
                                print("[DEBUG] 悬停加号点击, 当前选中操作: \(String(describing: viewModel.selectedActionType))")
                                DispatchQueue.main.async {
                                    if let actionType = viewModel.selectedActionType {
                                        print("[DEBUG] 创建新菜单项, 类型: \(actionType)")
                                        let newItem = MenuItem(
                                            name: actionTypeDisplayName(actionType),
                                            icon: actionTypeIcon(actionType),
                                            action: Action(type: actionType, parameter: nil),
                                            children: nil
                                        )
                                        viewModel.addMenuItem(newItem, to: item)
                                    } else {
                                        print("[DEBUG] 未选中操作类型, 添加默认新项目")
                                        let newItem = MenuItem(
                                            name: "新项目",
                                            icon: "doc",
                                            action: Action(type: .createEmptyFile, parameter: "txt"),
                                            children: nil
                                        )
                                        viewModel.addMenuItem(newItem, to: item)
                                    }
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .help("添加子项")
                        }
                        
                        Button {
                            viewModel.removeMenuItem(item)
                            if selectedItemId == item.id {
                                selectedItemId = nil
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("删除此项")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedItemId == item.id ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedItemId = item.id
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            
            // 子项目
            if hasChildren && isExpanded {
                ForEach(item.children ?? []) { childItem in
                    MenuItemTreeView(
                        item: childItem,
                        level: level + 1,
                        selectedItemId: $selectedItemId,
                        expandedItems: $expandedItems
                    )
                    .environmentObject(viewModel)
                }
            }
        }
    }
    
    private var iconColor: Color {
        if let action = item.action {
            switch action.type {
            case .separator:
                return .secondary
            case .createFileFromTemplate:
                return .accentColor
            case .createEmptyFile:
                return .blue
            case .createFolder:
                return .green
            case .openTerminal:
                return .black
            case .copyFilePath:
                return .orange
            case .cutFile:
                return .red
            case .runShellScript:
                return .purple
            }
        }
        
        if hasChildren {
            return .orange
        }
        
        return .secondary
    }
}

// ActionType显示名和图标辅助方法
private func actionTypeDisplayName(_ type: ActionType) -> String {
    switch type {
    case .createEmptyFile: return "新建空文件"
    case .createFileFromTemplate: return "模板文件"
    case .createFolder: return "新建文件夹"
    case .openTerminal: return "打开终端"
    case .copyFilePath: return "复制路径"
    case .cutFile: return "剪切文件"
    case .runShellScript: return "运行脚本"
    case .separator: return "分隔线"
    }
}
private func actionTypeIcon(_ type: ActionType) -> String {
    switch type {
    case .createEmptyFile: return "doc"
    case .createFileFromTemplate: return "doc.badge.plus"
    case .createFolder: return "folder"
    case .openTerminal: return "terminal"
    case .copyFilePath: return "doc.on.doc"
    case .cutFile: return "scissors"
    case .runShellScript: return "play"
    case .separator: return "minus"
    }
}

#Preview {
    MenuEditorView()
        .environmentObject(AppViewModel())
}
