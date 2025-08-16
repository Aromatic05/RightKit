//
//  TemplateLibraryView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI
import UniformTypeIdentifiers

struct TemplateLibraryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingFilePicker = false
    @State private var draggedTemplate: TemplateInfo?
    @State private var showActionLibrary = true
    @State private var showTemplateLibrary = true
    
    // 获取所有操作类型
    private var allActions: [ActionType] {
        return [
            .createEmptyFile,
            .createFileFromTemplate,
            .createFolder,
            .openTerminal,
            .copyFilePath,
            .cutFile,
            .runShellScript,
            .separator
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("模板与操作库")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    showingFilePicker = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                .help("添加新模板")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            Divider()
                .padding(.top, 12)
            // 操作库折叠菜单
            DisclosureGroup(isExpanded: $showActionLibrary) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allActions, id: \ .self) { actionType in
                        Button(action: {
                            let item = MenuItem(
                                name: actionTypeDisplayName(actionType),
                                icon: actionTypeIcon(actionType),
                                action: Action(type: actionType, parameter: nil),
                                children: nil
                            )
                            viewModel.addMenuItem(item)
                        }) {
                            HStack {
                                Image(systemName: actionTypeIcon(actionType))
                                    .foregroundColor(.accentColor)
                                Text(actionTypeDisplayName(actionType))
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } label: {
                Text("操作库")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            // 模板库折叠菜单
            DisclosureGroup(isExpanded: $showTemplateLibrary) {
                if viewModel.templates.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("暂无模板")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("点击 + 按钮添加模板文件")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("文件模板")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        List {
                            ForEach(viewModel.templates) { template in
                                TemplateRowView(template: template)
                                    .environmentObject(viewModel)
                            }
                            .onDelete(perform: deleteTemplates)
                        }
                        .listStyle(.sidebar)
                    }
                }
            } label: {
                Text("模板库")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.addTemplate(from: url)
                }
            case .failure(let error):
                NSLog("File picker error: \(error)")
            }
        }
    }
    // 操作类型显示名
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
    // 操作类型图标
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
    private func deleteTemplates(offsets: IndexSet) {
        for index in offsets {
            viewModel.removeTemplate(at: index)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TemplateRowView: View {
    let template: TemplateInfo
    @EnvironmentObject var viewModel: AppViewModel
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            if let iconName = template.iconName {
                Image(systemName: iconName)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
            } else {
                Image(systemName: "doc")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(template.displayName)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(template.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered {
                Button("添加到菜单") {
                    viewModel.createMenuItemFromTemplate(template)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .draggable(template) {
            HStack {
                Image(systemName: template.iconName ?? "doc")
                Text(template.displayName)
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    TemplateLibraryView()
        .environmentObject(AppViewModel())
}
