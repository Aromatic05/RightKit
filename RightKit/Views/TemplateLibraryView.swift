import SwiftUI
import UniformTypeIdentifiers

struct TemplateLibraryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    // MARK: - 本地状态变量
    @State private var showingFilePicker = false
    @State private var showActionLibrary = true
    @State private var showTemplateLibrary = true
    @State private var selectedTemplate: TemplateInfo? = nil
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: TemplateInfo? = nil
    
    // (修复第一步): 创建一个本地的 @State 变量来管理 List 的选择
    @State private var localSelectedActionType: ActionType?

    // 新增本地选中索引
    @State private var selectedActionIndex: Int? = nil

    // 获取所有操作类型（最后一个 nil 表示"子菜单"）
    private var allActions: [ActionType?] {
        return [
            .createEmptyFile,
            .createFileFromTemplate,
            .createFolder,
            .openTerminal,
            .copyFilePath,
            .cutFile,
            .runShellScript,
            .separator,
            nil // nil 表示"子菜单"
        ]
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // 标题栏
            HStack {
                Text("模板与操作库")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            Divider()
                .padding(.top, 0)
            
            // 操作库折叠菜单
            DisclosureGroup(
                isExpanded: $showActionLibrary,
                content: {
                    // (修复第二步): 将 List 的 selection 绑定到本地的 @State 变量
                    List(allActions.indices, id: \.self, selection: $selectedActionIndex) { idx in
                        let actionType = allActions[idx]
                        HStack {
                            if let type = actionType {
                                Image(systemName: ActionTypeUtils.icon(for: type))
                                    .foregroundColor(.accentColor)
                                Text(ActionTypeUtils.displayName(for: type))
                            } else {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.accentColor)
                                Text("子菜单")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .frame(minWidth: 180, maxWidth: 320, minHeight: 220, maxHeight: 320)
                    .frame(maxWidth: .infinity, alignment: .center)
                },
                label: {
                    HStack {
                        Text("操作库")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help("添加新操作（暂未实现）")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .padding(.leading, 12)
                }
            )
            .padding(.horizontal, 0)
            .padding(.vertical, 4)
            .padding(.leading, 12)
            
            // 模板库折叠菜单
            DisclosureGroup(
                isExpanded: $showTemplateLibrary,
                content: {
                    if viewModel.templates.isEmpty {
                        VStack(alignment: .center) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("暂无模板")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("点击 + 按钮添加模板文件")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                    } else {
                        List(viewModel.templates, id: \.id, selection: $selectedTemplate) { template in
                            HStack(spacing: 12) {
                                Image(systemName: template.iconName ?? "doc")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.displayName)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(template.fileName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // 删除按钮
                                Button(action: {
                                    templateToDelete = template
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.borderless)
                                .help("删除模板")
                            }
                            .contentShape(Rectangle())
                        }
                        .frame(minWidth: 180, maxWidth: 320, minHeight: 220, maxHeight: 320)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                },
                label: {
                    HStack {
                        Text("模板库")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button(action: { showingFilePicker = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help("添加新模板")
                        
                        // 刷新按钮
                        Button(action: {
                            viewModel.loadTemplates()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                        .help("刷新模板列表")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .padding(.leading, 12)
                }
            )
            .padding(.horizontal, 0)
            .padding(.vertical, 4)
            .padding(.leading, 12)
            
            Spacer(minLength: 0)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // 启动安全范围访问
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    DispatchQueue.main.async {
                        viewModel.addTemplate(from: url)
                    }
                }
            case .failure(let error):
                NSLog("File picker error: \(error)")
            }
        }
        .alert("删除模板", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let template = templateToDelete {
                    viewModel.removeTemplate(template.fileName)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("确定要删除模板 \"\(template.displayName)\" 吗？此操作无法撤销。")
            }
        }
        // (推荐): 在视图出现时，用 viewModel 的值初始化本地状态
        .onAppear {
            if let type = viewModel.selectedActionType {
                selectedActionIndex = allActions.firstIndex(where: { $0 == type })
            } else {
                selectedActionIndex = allActions.firstIndex(where: { $0 == nil })
            }
            // 刷新模板列表
            viewModel.loadTemplates()
        }
        // (修复第三步): 监听本地状态的变化，然后在这里更新 viewModel
        .onChange(of: selectedActionIndex) {
            if let idx = selectedActionIndex {
                viewModel.selectedActionType = allActions[idx]
            }
        }
    }
}

#Preview {
    TemplateLibraryView()
        .environmentObject(AppViewModel())
}
