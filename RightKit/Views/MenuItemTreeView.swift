//
//  MenuItemTreeView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/16.
//

import SwiftUI

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
    
    private var isSubmenu: Bool {
        item.action == nil
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
                if isSubmenu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if item.children == nil {
                                viewModel.initializeChildren(for: item)
                            }
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
                Text(ActionTypeUtils.displayName(for: item.action?.type))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                // 悬停时的操作按钮
                if isHovered {
                    HStack(spacing: 4) {
                        if isSubmenu {
                            Button {
                                DispatchQueue.main.async {
                                    let selectedType = viewModel.selectedActionType
                                    if selectedType == nil {
                                        let newItem = MenuItem(
                                            name: "新子菜单",
                                            icon: "list.bullet",
                                            action: nil,
                                            children: nil
                                        )
                                        viewModel.addMenuItem(newItem, to: item)
                                    } else if let type = selectedType {
                                        let newItem = MenuItem(
                                            name: ActionTypeUtils.displayName(for: type),
                                            icon: ActionTypeUtils.icon(for: type),
                                            action: Action(type: type, parameter: nil),
                                            children: nil
                                        )
                                        viewModel.addMenuItem(newItem, to: item)
                                    } else {
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
                            .help("添加子项或子菜单")
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
            if isSubmenu && isExpanded {
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
            case .openWithApp:
                return .yellow
            case .runShellScript:
                return .purple
            case .sendToDesktop:
                return .cyan
            case .hashFile:
                return .pink
            case .deleteFile:
                return .red
            case .showHiddenFiles:
                return .gray
            }
        }
        
        if hasChildren {
            return .orange
        }
        
        return .secondary
    }
}

// Removed local utility functions: actionTypeDisplayName, actionTypeIcon
