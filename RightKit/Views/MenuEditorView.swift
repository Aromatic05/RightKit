//
//  MenuEditorView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

struct MenuEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedItem: MenuItem?
    @State private var expandedItems: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("右键菜单结构")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("添加子菜单") {
                        viewModel.addSubmenu()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("添加分隔线") {
                        viewModel.addSeparator()
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
                                selectedItem: $selectedItem,
                                expandedItems: $expandedItems
                            )
                            .environmentObject(viewModel)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 底部详情编辑区域
            if let selectedItem = selectedItem {
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
    @Binding var selectedItem: MenuItem?
    @Binding var expandedItems: Set<String>
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
                                let newItem = MenuItem(
                                    name: "新项目",
                                    icon: "doc",
                                    action: Action(type: .createEmptyFile, parameter: "txt"),
                                    children: nil
                                )
                                viewModel.addMenuItem(newItem, to: item)
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .help("添加子项")
                        }
                        
                        Button {
                            viewModel.removeMenuItem(item)
                            if selectedItem?.id == item.id {
                                selectedItem = nil
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
                    .fill(selectedItem?.id == item.id ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedItem = item
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
                        selectedItem: $selectedItem,
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

struct MenuItemDetailEditor: View {
    let item: MenuItem
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editedName: String = ""
    @State private var editedIcon: String = ""
    @State private var editedParameter: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("编辑菜单项")
                .font(.headline)
            
            // 名称编辑
            VStack(alignment: .leading, spacing: 4) {
                Text("显示名称")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("菜单项名称", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !editedName.isEmpty {
                            viewModel.updateMenuItem(item, name: editedName)
                        }
                    }
            }
            
            // 图标编辑
            VStack(alignment: .leading, spacing: 4) {
                Text("图标 (SF Symbols)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("图标名称", text: $editedIcon)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.updateMenuItem(item, icon: editedIcon.isEmpty ? nil : editedIcon)
                        }
                    
                    if !editedIcon.isEmpty {
                        Image(systemName: editedIcon)
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                    }
                }
            }
            
            // 参数编辑（仅对某些动作类型显示）
            if let action = item.action, shouldShowParameterEditor(for: action.type) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(parameterLabel(for: action.type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField(parameterPlaceholder(for: action.type), text: $editedParameter)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // 类型信息
            VStack(alignment: .leading, spacing: 4) {
                Text("类型")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.typeDescription)
                    .font(.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .onAppear {
            editedName = item.name
            editedIcon = item.icon ?? ""
            editedParameter = item.action?.parameter ?? ""
        }
        .onChange(of: item) { newItem, _ in
            editedName = newItem.name
            editedIcon = newItem.icon ?? ""
            editedParameter = newItem.action?.parameter ?? ""
        }
    }
    
    private func shouldShowParameterEditor(for actionType: ActionType) -> Bool {
        switch actionType {
        case .createEmptyFile, .createFileFromTemplate, .runShellScript:
            return true
        default:
            return false
        }
    }
    
    private func parameterLabel(for actionType: ActionType) -> String {
        switch actionType {
        case .createEmptyFile:
            return "文件扩展名"
        case .createFileFromTemplate:
            return "模板文件名"
        case .runShellScript:
            return "脚本命令"
        default:
            return "参数"
        }
    }
    
    private func parameterPlaceholder(for actionType: ActionType) -> String {
        switch actionType {
        case .createEmptyFile:
            return "txt"
        case .createFileFromTemplate:
            return "template.txt"
        case .runShellScript:
            return "echo 'Hello World'"
        default:
            return "参数值"
        }
    }
}

#Preview {
    MenuEditorView()
        .environmentObject(AppViewModel())
}
