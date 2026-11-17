import SwiftUI

/// 新建或编辑一条自定义职业。取消不落盘；名称、提示词为空或和已有名称重复时留在这个窗口里说明原因。
struct ProfessionEditorSheet: View {
    var existing: CustomProfession?

    @Environment(BeanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var prompt: String
    @State private var error: String?
    @State private var confirmDiscard = false
    @FocusState private var focusName: Bool

    init(existing: CustomProfession?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _prompt = State(initialValue: existing?.prompt ?? "")
    }

    private var dirty: Bool {
        name != (existing?.name ?? "") || prompt != (existing?.prompt ?? "")
    }

    var body: some View {
        #if os(macOS)
        mac
        #else
        ios
        #endif
    }

    #if os(macOS)
    private var mac: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold())
            Text(intro).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            fields
            if let error {
                Text(error).font(.callout).foregroundStyle(Theme.rec).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Button(String(localized: "取消"), action: cancel)
                Button(String(localized: "保存"), action: save)
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 480)
        .onAppear { focusName = true }
        .onChange(of: name) { _, _ in error = nil }
        .onChange(of: prompt) { _, _ in error = nil }
        .interactiveDismissDisabled(dirty)
        .discardAlert($confirmDiscard) { dismiss() }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "名称")).font(.callout)
            TextField(String(localized: "名称"), text: $name, prompt: Text(String(localized: "比如：开源维护者")))
                .textFieldStyle(.roundedBorder)
                .focused($focusName)
            Text(String(localized: "整理时要留意什么")).font(.callout).padding(.top, 4)
            TextField(String(localized: "整理时要留意什么"), text: $prompt, prompt: Text(String(localized: "比如：格外留意兼容性、破坏性改动和需要回复的问题。")), axis: .vertical)
                .lineLimit(4...12)
                .textFieldStyle(.roundedBorder)
        }
    }
    #endif

    #if !os(macOS)
    private var ios: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "名称"), text: $name, prompt: Text(String(localized: "比如：开源维护者")))
                        .focused($focusName)
                } header: {
                    Text("名称")
                } footer: {
                    Text("显示在职业列表里。")
                }
                Section {
                    TextField(String(localized: "整理时要留意什么"), text: $prompt, prompt: Text(String(localized: "比如：格外留意兼容性、破坏性改动和需要回复的问题。")), axis: .vertical)
                        .lineLimit(5...12)
                } header: {
                    Text("整理时要留意什么")
                } footer: {
                    Text(intro)
                }
                if let error {
                    Section { Text(error).foregroundStyle(Theme.rec) }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(String(localized: "取消"), action: cancel) }
                ToolbarItem(placement: .confirmationAction) { Button(String(localized: "保存"), action: save) }
            }
            .onAppear { focusName = true }
            .onChange(of: name) { _, _ in error = nil }
            .onChange(of: prompt) { _, _ in error = nil }
            .interactiveDismissDisabled(dirty)
            .discardAlert($confirmDiscard) { dismiss() }
        }
    }
    #endif

    private var title: String {
        existing == nil ? String(localized: "新建自定义职业") : String(localized: "编辑自定义职业")
    }

    private var intro: String {
        String(localized: "名称显示在列表里。下面这段话会原样写进整理纪要的提示词，接在职业名后面，告诉模型该格外留意什么。")
    }

    private func cancel() {
        if dirty { confirmDiscard = true } else { dismiss() }
    }

    private func save() {
        let result: ProfessionEditError?
        if let existing {
            result = store.settings.updateCustomProfession(id: existing.id, name: name, prompt: prompt)
        } else {
            result = store.settings.addCustomProfession(name: name, prompt: prompt)
        }
        if let result {
            error = result.message
        } else {
            dismiss()
        }
    }
}

/// 打开编辑窗口用的标识。existing 为空就是新建。
struct ProfessionEditorRequest: Identifiable {
    let id = UUID()
    var existing: CustomProfession?
}

private extension View {
    func discardAlert(_ presented: Binding<Bool>, discard: @escaping () -> Void) -> some View {
        alert(String(localized: "放弃这次编辑？"), isPresented: presented) {
            Button(String(localized: "继续编辑"), role: .cancel) {}
            Button(String(localized: "放弃"), role: .destructive, action: discard)
        } message: {
            Text(String(localized: "名称和整理要求还没保存。"))
        }
    }
}
