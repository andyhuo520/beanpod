import Foundation

// 苹果平台的 String(localized:) 在开源 Swift 工具链里没有。这里补一个同名入口，
// 让同一份职业逻辑能在 Linux 上做类型检查和单元测试；Mac / iPhone 仍走系统的本地化。
#if os(Linux)
extension String {
    init(localized key: String) { self = key }
}
#endif

// MARK: - 职业

/// 使用者的职业。决定整理纪要时更看重什么。
/// 预设的属性和文案保持原样。自己加的职业是 CustomProfession，选中后折成 SelectedProfession 再交给原来的提示词。
nonisolated enum Profession: String, CaseIterable, Identifiable, Sendable {
    case general, sales, creator, product, founder, consultant, researcher, teacher, lawyer, doctor, student

    var id: String { rawValue }

    var name: String {
        switch self {
        case .general: String(localized: "通用")
        case .sales: String(localized: "销售与商务")
        case .creator: String(localized: "自媒体创作者")
        case .product: String(localized: "产品与运营")
        case .founder: String(localized: "创业者与管理者")
        case .consultant: String(localized: "咨询顾问")
        case .researcher: String(localized: "记者与研究员")
        case .teacher: String(localized: "教师与培训师")
        case .lawyer: String(localized: "律师")
        case .doctor: String(localized: "医生")
        case .student: String(localized: "学生")
        }
    }

    var focus: String {
        switch self {
        case .general: String(localized: "抓住结论、事实和后续要做的事。")
        case .sales: String(localized: "格外留意客户的真实需求、预算、决策链、异议和下一步动作；金额、日期、人名要原样记下。")
        case .creator: String(localized: "格外留意能做成选题的观点、可直接引用的金句、有故事性的片段和具体数据。")
        case .product: String(localized: "格外留意用户问题、需求优先级、方案取舍、排期和负责人。")
        case .founder: String(localized: "格外留意决策、资源分配、风险、人事和需要亲自跟进的事。")
        case .consultant: String(localized: "格外留意客户现状、痛点、假设、需要验证的数据和交付物。")
        case .researcher: String(localized: "格外留意可引用的原话、事实与来源、前后矛盾之处和值得追问的线索。")
        case .teacher: String(localized: "格外留意知识结构、例子、学员的疑问和需要补讲的地方。")
        case .lawyer: String(localized: "格外留意事实经过、时间点、各方主张、证据线索和承诺；不做法律判断，只记录。")
        case .doctor: String(localized: "格外留意主诉、病史、用药、检查和医嘱；不做诊断，只记录原话。")
        case .student: String(localized: "格外留意知识点、考点、老师强调的内容和作业要求。")
        }
    }

    /// 给模型看的职业名和关注点，固定中文（提示词不跟界面语言走）。
    var promptName: String {
        switch self {
        case .general: "通用"
        case .sales: "销售与商务"
        case .creator: "自媒体创作者"
        case .product: "产品与运营"
        case .founder: "创业者与管理者"
        case .consultant: "咨询顾问"
        case .researcher: "记者与研究员"
        case .teacher: "教师与培训师"
        case .lawyer: "律师"
        case .doctor: "医生"
        case .student: "学生"
        }
    }

    var promptFocus: String {
        switch self {
        case .general: "抓住结论、事实和后续要做的事。"
        case .sales: "格外留意客户的真实需求、预算、决策链、异议和下一步动作；金额、日期、人名要原样记下。"
        case .creator: "格外留意能做成选题的观点、可直接引用的金句、有故事性的片段和具体数据。"
        case .product: "格外留意用户问题、需求优先级、方案取舍、排期和负责人。"
        case .founder: "格外留意决策、资源分配、风险、人事和需要亲自跟进的事。"
        case .consultant: "格外留意客户现状、痛点、假设、需要验证的数据和交付物。"
        case .researcher: "格外留意可引用的原话、事实与来源、前后矛盾之处和值得追问的线索。"
        case .teacher: "格外留意知识结构、例子、学员的疑问和需要补讲的地方。"
        case .lawyer: "格外留意事实经过、时间点、各方主张、证据线索和承诺；不做法律判断，只记录。"
        case .doctor: "格外留意主诉、病史、用药、检查和医嘱；不做诊断，只记录原话。"
        case .student: "格外留意知识点、考点、老师强调的内容和作业要求。"
        }
    }
}

/// 用户自己加的职业：名称，加上写进整理提示词的那段话。只存在这台设备的偏好里，不写进录音。
nonisolated struct CustomProfession: Codable, Equatable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var prompt: String
}

/// 当前选中的职业。预设走原来的 name / focus / promptName / promptFocus；自定义项用用户写的 name 和 prompt 填进同样的位置。
nonisolated struct SelectedProfession: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var focus: String
    var promptName: String
    var promptFocus: String
    var builtin: Bool

    init(builtin: Profession) {
        id = builtin.rawValue
        name = builtin.name
        focus = builtin.focus
        promptName = builtin.promptName
        promptFocus = builtin.promptFocus
        self.builtin = true
    }

    init(custom: CustomProfession) {
        id = custom.id
        name = custom.name
        focus = custom.prompt
        promptName = custom.name
        promptFocus = custom.prompt
        builtin = false
    }

    static func resolve(_ id: String, customs: [CustomProfession]) -> SelectedProfession {
        if let builtin = Profession(rawValue: id) { return SelectedProfession(builtin: builtin) }
        if let custom = customs.first(where: { $0.id == id }) { return SelectedProfession(custom: custom) }
        return SelectedProfession(builtin: .general)
    }

    /// 设置行里的说明。内置项用完整的本地化关注点；自定义项把多行收成一行，太长就截断。
    var settingsDetail: String {
        guard !builtin else { return focus }
        let flat = focus.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard flat.count > 72 else { return flat }
        return String(flat.prefix(72)) + "…"
    }
}

nonisolated enum ProfessionEditError: Equatable, Sendable {
    case emptyName, emptyPrompt, duplicateName(String), notFound

    var message: String {
        switch self {
        case .emptyName: String(localized: "请填写名称。")
        case .emptyPrompt: String(localized: "请填写整理时要留意的内容。")
        case .duplicateName(let name): String(localized: "已经有一个叫「\(name)」的职业。")
        case .notFound: String(localized: "这个自定义职业已经不在了。")
        }
    }
}

/// 职业列表和当前选择。选中项仍用原来的键 "profession"（内置项的代号和以前一样）。
nonisolated struct ProfessionLibrary: Equatable, Sendable {
    static let selectionKey = "profession"
    static let customKey = "customProfessions"

    /// 英文界面名。用来拦「General」这种和预设重名的自定义，即使用户当前界面是中文。
    private static let englishNames = [
        "general": "General", "sales": "Sales & business", "creator": "Content creator",
        "product": "Product & operations", "founder": "Founder / manager", "consultant": "Consultant",
        "researcher": "Journalist / researcher", "teacher": "Teacher / trainer",
        "lawyer": "Lawyer", "doctor": "Doctor", "student": "Student",
    ]

    var customs: [CustomProfession]
    var selectedID: String

    var selected: SelectedProfession { SelectedProfession.resolve(selectedID, customs: customs) }

    /// 读偏好。selectionWasInvalid 为 true 时，存着的 id 已经对不上任何职业，调用方应把选中项写回「通用」。
    /// 空着没存过不算无效，也不写盘，避免给没改过设置的人凭空加一条偏好。
    static func load(from defaults: UserDefaults) -> (library: ProfessionLibrary, selectionWasInvalid: Bool) {
        let customs = readCustoms(defaults)
        let stored = defaults.string(forKey: selectionKey) ?? ""
        let resolved = SelectedProfession.resolve(stored, customs: customs)
        let invalid = !stored.isEmpty && resolved.id != stored
        return (ProfessionLibrary(customs: customs, selectedID: resolved.id), invalid)
    }

    func save(to defaults: UserDefaults) {
        defaults.set(selectedID, forKey: Self.selectionKey)
        defaults.set(Self.stored(customs), forKey: Self.customKey)
    }

    static func stored(_ customs: [CustomProfession]) -> [[String: String]] {
        customs.map { ["id": $0.id, "name": $0.name, "prompt": $0.prompt] }
    }

    static func cleanName(_ raw: String) -> String {
        raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static func cleanPrompt(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalize(_ raw: String) -> String {
        cleanName(raw).folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "zh-Hans"))
    }

    func validate(name rawName: String, prompt rawPrompt: String, editing: String?) -> ProfessionEditError? {
        let name = Self.cleanName(rawName)
        let prompt = Self.cleanPrompt(rawPrompt)
        if name.isEmpty { return .emptyName }
        if prompt.isEmpty { return .emptyPrompt }
        if takenNames(editing: editing).contains(Self.normalize(name)) { return .duplicateName(name) }
        return nil
    }

    /// 加上并选中。校验不过时列表和选中项都不变。
    mutating func add(name: String, prompt: String) -> ProfessionEditError? {
        if let error = validate(name: name, prompt: prompt, editing: nil) { return error }
        let item = CustomProfession(id: UUID().uuidString, name: Self.cleanName(name), prompt: Self.cleanPrompt(prompt))
        customs.append(item)
        selectedID = item.id
        return nil
    }

    /// 改名称或提示词，id 不变，所以正在用它的选择还在。
    mutating func update(id: String, name: String, prompt: String) -> ProfessionEditError? {
        guard let index = customs.firstIndex(where: { $0.id == id }) else { return .notFound }
        if let error = validate(name: name, prompt: prompt, editing: id) { return error }
        customs[index].name = Self.cleanName(name)
        customs[index].prompt = Self.cleanPrompt(prompt)
        return nil
    }

    /// 删掉自己建的一项。删的是当前选中项时，回到「通用」。内置项删不掉。
    @discardableResult
    mutating func delete(id: String) -> Bool {
        guard let index = customs.firstIndex(where: { $0.id == id }) else { return false }
        customs.remove(at: index)
        if selectedID == id { selectedID = Profession.general.rawValue }
        return true
    }

    private func takenNames(editing: String?) -> Set<String> {
        var names: [String] = []
        for builtin in Profession.allCases {
            names.append(builtin.promptName)
            names.append(builtin.name)
            if let english = Self.englishNames[builtin.rawValue] { names.append(english) }
        }
        for custom in customs where custom.id != editing {
            names.append(custom.name)
        }
        return Set(names.map(Self.normalize))
    }

    private static func readCustoms(_ defaults: UserDefaults) -> [CustomProfession] {
        guard let raw = defaults.array(forKey: customKey) else { return [] }
        return raw.compactMap { item in
            guard let row = item as? [String: Any],
                  let id = row["id"] as? String, !id.isEmpty, Profession(rawValue: id) == nil,
                  let name = (row["name"] as? String) ?? (row["label"] as? String), !name.isEmpty,
                  let prompt = row["prompt"] as? String, !prompt.isEmpty else { return nil }
            return CustomProfession(id: id, name: name, prompt: prompt)
        }
    }
}

extension SelectedProfession {
    /// 场景说明在提示词里的一行。整理时仍由 Scene 逐条提供内容，这里只固定拼接格式。
    static func sceneGuideLine(code: String, name: String, definition: String, headings: [String]) -> String {
        "- \(code)（\(name)）：\(definition)。栏目：\(headings.joined(separator: "、"))"
    }

    /// 整理纪要的系统提示词。职业那一句仍是原来的 promptName、promptFocus；场景规则和栏目说明接在后面。
    func analysisSystem(fixedSceneCode: String?, sceneGuide: String, titleHint: String, notesRule: String) -> String {
        let sceneRule = fixedSceneCode.map { "场景已经确定是 \($0)，不要改。" }
            ?? "先判断场景，从下面的英文代号里选一个。"
        return """
        你是录音整理助手。使用者的职业是「\(promptName)」，\(promptFocus)

        \(sceneRule)
        \(sceneGuide)

        然后只输出一个 JSON 对象，不要任何别的文字：
        {
          "scene": "场景的英文代号",
          "title": "\(titleHint)，说清这段录音是什么事",
          "summary": "两到四句话的摘要，先说结论",
          "sections": [{"heading": "所选场景的栏目名", "items": ["这一栏下的要点，每条一句完整的话"]}],
          "todos": ["后续要做的事，写清谁、做什么、什么时候；没有就给空数组"],
          "tags": ["2 到 5 个主题标签，名词，不带 #"],
          "people": ["出现的人名或称呼；没有就给空数组"]
        }

        要求：
        - sections 必须使用所选场景的栏目名，某一栏没有内容就不要输出这一栏。
        - 只写录音里真有的内容。数字、金额、日期、人名照原样写，听不清的不要猜。
        - \(notesRule)
        """
    }

    /// 改写用的系统提示词。内置项保持原来只写职业名的那一句；自定义项在同一处带上用户写的 prompt。
    func rewriteSystem(instruction: String) -> String {
        let lead = builtin
            ? "你是一位文字编辑。使用者的职业是「\(promptName)」。下面是他一段录音的内容，请按要求改写。"
            : "你是一位文字编辑。使用者的职业是「\(promptName)」，\(promptFocus)\n下面是他一段录音的内容，请按要求改写。"
        return """
        \(lead)
        要求：\(instruction)
        只用录音里有的事实、观点和例子，不要编造数据或经历。录音里的口语垫词不要带进成品。
        直接输出成品，不要解释你做了什么。
        """
    }
}
