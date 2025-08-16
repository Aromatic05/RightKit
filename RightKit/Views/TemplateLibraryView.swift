import SwiftUI
import UniformTypeIdentifiers

struct TemplateLibraryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    // MARK: - 本地状态变量
    @State private var showingFilePicker = false
    @State private var showActionLibrary = true
    @State private var showTemplateLibrary = true
    @State private var selectedTemplate: TemplateInfo? = nil
    
    // (修复第一步): 创建一个本地的 @State 变量来管理 List 的选择
    @State private var localSelectedActionType: ActionType?

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
                    List(allActions, id: \.self, selection: $localSelectedActionType) { actionType in
                        HStack {
                            Image(systemName: actionTypeIcon(actionType))
                                .foregroundColor(.accentColor)
                            Text(actionTypeDisplayName(actionType))
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
                    DispatchQueue.main.async {
                        viewModel.addTemplate(from: url)
                    }
                }
            case .failure(let error):
                NSLog("File picker error: \(error)")
            }
        }
        // (推荐): 在视图出现时，用 viewModel 的值初始化本地状态
        .onAppear {
            localSelectedActionType = viewModel.selectedActionType
        }
        // (修复第三步): 监听本地状态的变化，然后在这里更新 viewModel
        .onChange(of: localSelectedActionType) { newValue in
            viewModel.selectedActionType = newValue
        }
    }
    
    // ... private func ... (这部分无需改动)
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
}

#Preview {
    TemplateLibraryView()
        .environmentObject(AppViewModel())
}
