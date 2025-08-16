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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("模板库")
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
            
            // 快速添加按钮
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("快速操作")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    QuickActionButton(
                        title: "空白文件",
                        icon: "doc",
                        color: .blue
                    ) {
                        viewModel.addEmptyFileAction()
                    }
                    
                    QuickActionButton(
                        title: "子菜单",
                        icon: "folder",
                        color: .orange
                    ) {
                        viewModel.addSubmenu()
                    }
                    
                    QuickActionButton(
                        title: "分隔线",
                        icon: "minus",
                        color: .gray
                    ) {
                        viewModel.addSeparator()
                    }
                    
                    QuickActionButton(
                        title: "新建文件夹",
                        icon: "folder.badge.plus",
                        color: .green
                    ) {
                        let folderAction = MenuItem(
                            name: "新建文件夹",
                            icon: "folder.badge.plus",
                            action: Action(type: .createFolder, parameter: nil),
                            children: nil
                        )
                        viewModel.addMenuItem(folderAction)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
                .padding(.top, 12)
            
            // 模板列表
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