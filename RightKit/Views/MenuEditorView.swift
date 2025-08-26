//
//  MenuEditorView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

struct MenuEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题栏
                HStack {
                    Text("右键菜单结构")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button("添加子项") {
                            DispatchQueue.main.async {
                                if viewModel.selectedActionType == nil {
                                    // 添加子菜单
                                    let newItem = MenuItem(
                                        name: "新子菜单",
                                        icon: "list.bullet",
                                        action: nil,
                                        children: []
                                    )
                                    viewModel.addMenuItem(newItem)
                                } else if let actionType = viewModel.selectedActionType {
                                    let newItem = MenuItem(
                                        name: ActionTypeUtils.displayName(for: actionType),
                                        icon: ActionTypeUtils.icon(for: actionType),
                                        action: Action(type: actionType, parameter: nil),
                                        children: nil
                                    )
                                    viewModel.addMenuItem(newItem)
                                } else {
                                    let newItem = MenuItem(
                                        name: "新项目",
                                        icon: "doc",
                                        action: Action(type: .createEmptyFile, parameter: "txt"),
                                        children: nil
                                    )
                                    viewModel.addMenuItem(newItem)
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
                                    selectedItemId: $viewModel.selectedItemId,
                                    expandedItems: $expandedItems
                            )
                            .environmentObject(viewModel)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 底部详情编辑区域
                if let selectedId = viewModel.selectedItemId {
                    Divider()
                    MenuItemDetailEditor(itemId: selectedId)
                        .id(selectedId)
                        .environmentObject(viewModel)
                        .padding(16)
                        .background(.regularMaterial)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 600) // 可根据实际需求调整
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

#Preview {
    MenuEditorView()
        .environmentObject(AppViewModel())
}
