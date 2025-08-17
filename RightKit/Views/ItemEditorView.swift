//
//  ItemEditorView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/16.
//

import SwiftUI

struct MenuItemDetailEditor: View {
    let itemId: UUID
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editedName: String = ""
    @State private var editedIcon: String = ""
    @State private var editedParameter: String = ""

    private var item: MenuItem? {
        findMenuItem(by: itemId, in: viewModel.menuItems)
    }
    private func findMenuItem(by id: UUID, in items: [MenuItem]) -> MenuItem? {
        for item in items {
            if item.id == id { return item }
            if let children = item.children, let found = findMenuItem(by: id, in: children) {
                return found
            }
        }
        return nil
    }
    private var hasChanges: Bool {
        guard let item = item else { return false }
        return editedName != item.name ||
        editedIcon != (item.icon ?? "") ||
        editedParameter != (item.action?.parameter ?? "")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("编辑菜单项")
                .font(.headline)
            if let item = item {
                VStack(alignment: .leading, spacing: 4) {
                    Text("显示名称")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("菜单项名称", text: $editedName)
                        .id(itemId)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !editedName.isEmpty {
                                viewModel.updateMenuItem(item, name: editedName)
                            }
                        }
                }
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
                if let action = item.action, ActionTypeUtils.shouldShowParameterEditor(for: action.type) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ActionTypeUtils.parameterLabel(for: action.type))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField(ActionTypeUtils.parameterPlaceholder(for: action.type), text: $editedParameter)
                            .textFieldStyle(.roundedBorder)
                    }
                }
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
            } else {
                Text("未找到菜单项")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if let item = item {
                editedName = item.name
                editedIcon = item.icon ?? ""
                editedParameter = item.action?.parameter ?? ""
            }
        }
        .onChange(of: itemId) { newId, _ in
            if let item = self.item {
                editedName = item.name
                editedIcon = item.icon ?? ""
                editedParameter = item.action?.parameter ?? ""
            }
        }
        .onChange(of: item) { newItem, _ in
            if let item = newItem {
                editedName = item.name
                editedIcon = item.icon ?? ""
                editedParameter = item.action?.parameter ?? ""
            }
        }
    }
}
