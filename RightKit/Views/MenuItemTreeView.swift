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
                                DispatchQueue.main.async {
                                    if let actionType = viewModel.selectedActionType {
                                        let newItem = MenuItem(
                                            name: ActionTypeUtils.displayName(for: actionType),
                                            icon: ActionTypeUtils.icon(for: actionType),
                                            action: Action(type: actionType, parameter: nil),
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

// Removed local utility functions: actionTypeDisplayName, actionTypeIcon
