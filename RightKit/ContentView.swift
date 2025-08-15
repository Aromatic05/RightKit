//
//  ContentView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

struct ContentView: View {
    @State private var templateFolderPath: String = "未选择"
    @State private var showingFolderPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("RightKit 设置")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)
                
                Divider()
                
                // 模板文件夹设置
                GroupBox("模板文件夹设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("当前模板文件夹:")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        HStack {
                            Text(templateFolderPath)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button("选择文件夹") {
                                showingFolderPicker = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Text("选择一个包含模板文件的文件夹，这些文件将出现在「从模板新建」菜单中。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // 功能说明
                GroupBox("功能说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("在 Finder 中右键点击文件夹或空白区域", systemImage: "hand.point.up.braille")
                        Label("选择「新建文件」创建各种类型的空白文件", systemImage: "doc.badge.plus")
                        Label("选择「从模板新建」使用预设模板创建文件", systemImage: "doc.on.doc")
                        Label("使用「工具」菜单进行文件操作", systemImage: "wrench.and.screwdriver")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态信息
                VStack {
                    Text("RightKit 扩展状态")
                        .font(.headline)
                    Text("请在「系统设置」>「隐私与安全性」>「扩展」中启用 RightKit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("RightKit")
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFolderSelection(result)
        }
        .alert("设置结果", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadCurrentTemplateFolderPath()
        }
    }
    
    private func loadCurrentTemplateFolderPath() {
        if let url = TemplateManager.getTemplateFolderURL() {
            templateFolderPath = url.path
        } else {
            templateFolderPath = "未选择"
        }
    }
    
    private func handleFolderSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            
            if TemplateManager.setTemplateFolder(selectedURL) {
                templateFolderPath = selectedURL.path
                alertMessage = "模板文件夹设置成功！\n路径: \(selectedURL.path)"
                showingAlert = true
                NSLog("Template folder set successfully: \(selectedURL.path)")
            } else {
                alertMessage = "设置模板文件夹失败，请重试。"
                showingAlert = true
                NSLog("Failed to set template folder")
            }
            
        case .failure(let error):
            alertMessage = "选择文件夹时出错: \(error.localizedDescription)"
            showingAlert = true
            NSLog("Error selecting folder: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
