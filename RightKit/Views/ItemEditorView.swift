//
//  ItemEditorView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/16.
//

import SwiftUI

struct MenuItemDetailEditor: View {
    let item: MenuItem
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editedName: String = ""
    @State private var editedIcon: String = ""
    @State private var editedParameter: String = ""
    
    // 新增：追踪是否有变更
    private var hasChanges: Bool {
        editedName != item.name ||
        editedIcon != (item.icon ?? "") ||
        editedParameter != (item.action?.parameter ?? "")
    }
    
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
            if let action = item.action, ActionTypeUtils.shouldShowParameterEditor(for: action.type) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ActionTypeUtils.parameterLabel(for: action.type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField(ActionTypeUtils.parameterPlaceholder(for: action.type), text: $editedParameter)
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
            // 新增：保存按钮
            HStack {
                Spacer()
                Button("保存") {
                    if editedName != item.name && !editedName.isEmpty {
                        viewModel.updateMenuItem(item, name: editedName)
                    }
                    if editedIcon != (item.icon ?? "") {
                        viewModel.updateMenuItem(item, icon: editedIcon.isEmpty ? nil : editedIcon)
                    }
                    if let action = item.action, ActionTypeUtils.shouldShowParameterEditor(for: action.type), editedParameter != (action.parameter ?? "") {
                        viewModel.updateMenuItem(item, parameter: editedParameter)
                    }
                }
                .disabled(!hasChanges)
                .buttonStyle(.borderedProminent)
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
}
