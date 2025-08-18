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
    @State private var templateFolderPath: String? = nil
    @State private var isTemplatefolderConfigured = false

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
            .openWithApp,
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
                    VStack(spacing: 12) {
                        // 模板目录状态和选择区域
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("模板目录")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if isTemplatefolderConfigured, let path = templateFolderPath {
                                        Text(path)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    } else {
                                        Text("未选择模板目录")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                // 选择/更改目录按钮
                                Button(action: {
                                    TemplateManager.selectTemplateFolderForUI { success in
                                        if success {
                                            updateTemplateFolderStatus()
                                        }
                                    }
                                }) {
                                    Text(isTemplatefolderConfigured ? "更改" : "选择")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 模板列表或提示
                        if !isTemplatefolderConfigured {
                            // 未配置目录的提示
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 8) {
                                    Text("需要选择模板目录")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    
                                    Text("请先选择一个文件夹作为模板存储位置，然后就可以添加和使用模板文件了。")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                
                                Button(action: {
                                    TemplateManager.initializeTemplateFolder()
                                    updateTemplateFolderStatus()
                                }) {
                                    Label("选择模板目录", systemImage: "folder.badge.plus")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                        } else if viewModel.templates.isEmpty {
                            // 已配置目录但无模板的提示
                            VStack(alignment: .center, spacing: 16) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("暂无模板文件")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                VStack(spacing: 4) {
                                    Text("点击上方 + 按钮添加模板文件")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    Text("或直接将文件拖拽到模板目录中")
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                        } else {
                            // 模板列表
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
                            .frame(minWidth: 180, maxWidth: 320, minHeight: 200, maxHeight: 280)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                },
                label: {
                    HStack {
                        Text("模板库")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Spacer()
                        
                        // 只有在配置了目录时才显示添加按钮
                        if isTemplatefolderConfigured {
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
                            
                            // 在Finder中显示目录按钮
                            Button(action: {
                                TemplateManager.revealTemplateFolderInFinder()
                            }) {
                                Image(systemName: "folder")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .help("在Finder中显示模板目录")
                        }
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
            // 更新模板目录状态
            updateTemplateFolderStatus()
            // 刷新模板列表
            viewModel.loadTemplates()
        }
        // (修复第三步): 监听本地状态的变化，然后在这里更新 viewModel
        .onChange(of: selectedActionIndex) {
            if let idx = selectedActionIndex {
                viewModel.selectedActionType = allActions[idx]
            }
        }
        // 监听模板文件夹更改通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TemplateFolderChanged"))) { _ in
            updateTemplateFolderStatus()
        }
    }
    
    // MARK: - 私有方法
    private func updateTemplateFolderStatus() {
        // 使用轻量级检查，不阻塞UI
        let hasStoredPath = TemplateManager.isTemplateFolderConfigured()
        templateFolderPath = TemplateManager.getCurrentTemplateFolderPath()
        isTemplatefolderConfigured = hasStoredPath
        
        // 如果有存储的路径，在后台验证访问权限
        if hasStoredPath {
            TemplateManager.validateTemplateFolderAccess { isValid in
                if isValid {
                    // 只有在验证成功时才刷新模板列表
                    viewModel.loadTemplates()
                } else {
                    // 如果无法访问，更新状态
                    self.isTemplatefolderConfigured = false
                }
            }
        }
    }
}

#Preview {
    TemplateLibraryView()
        .environmentObject(AppViewModel())
}
