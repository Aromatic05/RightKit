//
//  ContentView.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationSplitView {
            // 左侧面板：模板库
            TemplateLibraryView()
                .environmentObject(viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // 右侧面板：菜单编辑器
            MenuEditorView()
                .environmentObject(viewModel)
        }
        .navigationTitle("RightKit - 右键菜单管理器")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存更改") {
                    viewModel.saveMenuTree()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasChanges)
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button("重置为默认") {
                    viewModel.resetToDefaultData()
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            // 初始化配置和加载数据
            ConfigurationManager.initializeDefaultConfiguration()
            viewModel.loadMenuTree()
            viewModel.loadTemplates()
        }
    }
}

#Preview {
    ContentView()
}
