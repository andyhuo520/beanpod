import Foundation
import Testing
@testable import NotesCore

private let builtinPrompts: [(String, String, String)] = [
    ("general", "通用", "抓住结论、事实和后续要做的事。"),
    ("sales", "销售与商务", "格外留意客户的真实需求、预算、决策链、异议和下一步动作；金额、日期、人名要原样记下。"),
    ("creator", "自媒体创作者", "格外留意能做成选题的观点、可直接引用的金句、有故事性的片段和具体数据。"),
    ("product", "产品与运营", "格外留意用户问题、需求优先级、方案取舍、排期和负责人。"),
    ("founder", "创业者与管理者", "格外留意决策、资源分配、风险、人事和需要亲自跟进的事。"),
    ("consultant", "咨询顾问", "格外留意客户现状、痛点、假设、需要验证的数据和交付物。"),
    ("researcher", "记者与研究员", "格外留意可引用的原话、事实与来源、前后矛盾之处和值得追问的线索。"),
    ("teacher", "教师与培训师", "格外留意知识结构、例子、学员的疑问和需要补讲的地方。"),
    ("lawyer", "律师", "格外留意事实经过、时间点、各方主张、证据线索和承诺；不做法律判断，只记录。"),
    ("doctor", "医生", "格外留意主诉、病史、用药、检查和医嘱；不做诊断，只记录原话。"),
    ("student", "学生", "格外留意知识点、考点、老师强调的内容和作业要求。"),
]

private let sceneRows: [(String, String, String, [String])] = [
    ("meeting", "会议", "多人围绕议题讨论并形成决定的内部会议、例会、评审", ["结论与决定", "讨论要点", "分歧与风险"]),
    ("interview", "访谈", "一方提问一方回答：采访、用户访谈、面试、调研", ["核心观点", "原话金句", "值得追问"]),
    ("sales", "销售", "向客户介绍产品、谈价格、处理异议、推进成交", ["客户需求", "顾虑与异议", "预算与决策人", "下一步"]),
    ("talk", "沟通", "两三个人之间的交流：一对一、汇报、谈心、协商", ["达成的共识", "没谈拢的地方", "对方的诉求"]),
    ("call", "电话", "电话或语音通话，通常较短、目的单一", ["来电目的", "说定的事"]),
    ("media", "自媒体", "为发布内容而录：口播、选题讨论、脚本、播客录制", ["选题与角度", "可用金句", "可剪片段"]),
    ("conference", "大会", "一人对多人的公开演讲：发布会、论坛、行业大会", ["演讲主题", "核心观点", "数据与案例"]),
    ("lesson", "课程", "讲课、培训、讲座、读书分享等教学内容", ["知识点", "例子与方法", "没讲透的地方"]),
    ("memo", "灵感", "一个人自言自语记想法、备忘、灵感", ["想法", "可以怎么做"]),
    ("other", "其他", "以上都不像", ["要点"]),
]

private func sceneGuide() -> String {
    sceneRows.map { SelectedProfession.sceneGuideLine(code: $0.0, name: $0.1, definition: $0.2, headings: $0.3) }.joined(separator: "\n")
}

private func defaults() -> UserDefaults {
    let name = "ProfessionTests." + UUID().uuidString
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}

@Test func notesPathsUseTheSelectedProfessionPrompt() throws {
    let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let analyzer = try String(contentsOf: root.appendingPathComponent("Shared/Analyzer.swift"), encoding: .utf8)
    let pipeline = try String(contentsOf: root.appendingPathComponent("Shared/Pipeline.swift"), encoding: .utf8)
    #expect(analyzer.contains("Scene.allCases.map"))
    #expect(analyzer.contains("SelectedProfession.sceneGuideLine"))
    #expect(analyzer.contains("profession.analysisSystem"))
    #expect(analyzer.contains("profession.rewriteSystem(instruction:"))
    #expect(!analyzer.contains("promptFocus"))
    #expect(pipeline.contains("Analyzer.analyze(transcript: transcript, duration: duration, profession: profession"))
    #expect(pipeline.contains("Analyzer.rewrite(material: material, instruction: finalInstruction, profession: profession"))
}

@Test func builtinIdentifiersAndPromptsStayPut() {
    #expect(ProfessionLibrary.selectionKey == "profession")
    #expect(Profession.allCases.map(\.rawValue) == builtinPrompts.map(\.0))
    for row in builtinPrompts {
        let builtin = Profession(rawValue: row.0)!
        #expect(builtin.promptName == row.1)
        #expect(builtin.promptFocus == row.2)
        let profile = SelectedProfession(builtin: builtin)
        #expect(profile.builtin && profile.id == row.0 && profile.promptName == row.1 && profile.promptFocus == row.2)
    }
}

@Test func legacySelectionResolvesAndUnknownFallsBackToGeneral() {
    let d = defaults()
    for row in builtinPrompts {
        d.set(row.0, forKey: "profession")
        let loaded = ProfessionLibrary.load(from: d)
        #expect(!loaded.selectionWasInvalid)
        #expect(loaded.library.selectedID == row.0)
        #expect(loaded.library.selected.promptFocus == row.2)
        #expect(d.string(forKey: "profession") == row.0)
    }

    d.removeObject(forKey: "profession")
    let missing = ProfessionLibrary.load(from: d)
    #expect(!missing.selectionWasInvalid)
    #expect(missing.library.selectedID == "general")
    #expect(d.string(forKey: "profession") == nil)

    d.set("", forKey: "profession")
    let empty = ProfessionLibrary.load(from: d)
    #expect(!empty.selectionWasInvalid && empty.library.selectedID == "general")

    d.set("no-such-job", forKey: "profession")
    let unknown = ProfessionLibrary.load(from: d)
    #expect(unknown.selectionWasInvalid && unknown.library.selectedID == "general")
    #expect(unknown.library.selected.promptName == "通用")
}

@Test func customProfessionRoundTripEditAndDelete() {
    let d = defaults()
    d.set("founder", forKey: "profession")
    var library = ProfessionLibrary.load(from: d).library
    #expect(library.selectedID == "founder")

    let before = library
    #expect(library.add(name: "   ", prompt: "留意兼容性") == .emptyName)
    #expect(library.add(name: "开源维护者", prompt: " \n\n ") == .emptyPrompt)
    #expect(library.add(name: "通用", prompt: "随便写一点") == .duplicateName("通用"))
    #expect(library.add(name: " General ", prompt: "随便写一点") == .duplicateName("General"))
    #expect(library.add(name: "销售与商务", prompt: "随便写一点") == .duplicateName("销售与商务"))
    #expect(library == before)

    #expect(library.add(name: " 开源维护者 ", prompt: "留意兼容性。\n不要替用户做决定。") == nil)
    let created = library.customs[0]
    #expect(created.name == "开源维护者")
    #expect(created.prompt == "留意兼容性。\n不要替用户做决定。")
    #expect(library.selectedID == created.id)
    #expect(Profession(rawValue: created.id) == nil)
    #expect(library.selected.promptName == "开源维护者")
    #expect(library.selected.promptFocus == created.prompt)
    #expect(!library.selected.builtin)

    #expect(library.add(name: "pm", prompt: "留意排期") == nil)
    #expect(library.customs.count == 2)
    let pm = library.customs[1]
    #expect(library.update(id: created.id, name: "PM", prompt: "别的说明") == .duplicateName("PM"))
    #expect(library.customs[0].name == "开源维护者")
    #expect(library.update(id: pm.id, name: "PM", prompt: "留意排期和负责人") == nil)
    #expect(library.customs[1].name == "PM" && library.customs[1].id == pm.id)
    #expect(library.update(id: created.id, name: "开源维护者", prompt: "留意兼容性和发行说明。") == nil)
    #expect(library.customs[0].id == created.id)
    #expect(library.customs[0].prompt == "留意兼容性和发行说明。")
    #expect(library.update(id: "missing", name: "别的", prompt: "内容") == .notFound)

    library.selectedID = "founder"
    let removedPM = library.delete(id: pm.id)
    #expect(removedPM)
    #expect(library.selectedID == "founder")
    #expect(library.customs.map(\.id) == [created.id])
    let removedBuiltin = library.delete(id: "founder")
    #expect(!removedBuiltin)
    let removedCreated = library.delete(id: created.id)
    #expect(removedCreated)
    // 删的不是当前选中项，选择留在原来的内置职业上。
    #expect(library.selectedID == "founder")
    #expect(library.customs.isEmpty)

    #expect(library.add(name: "播客主播", prompt: "留意可以独立成集的故事和需要核对的数字。") == nil)
    library.save(to: d)
    let again = ProfessionLibrary.load(from: d)
    #expect(!again.selectionWasInvalid)
    #expect(again.library.customs == library.customs)
    #expect(again.library.selectedID == library.selectedID)
    #expect(again.library.selected.promptFocus == "留意可以独立成集的故事和需要核对的数字。")

    // 旧的职业选择旁边可以同时存着自定义项，重新读出来两边都在。
    d.set("lawyer", forKey: "profession")
    let mixed = ProfessionLibrary.load(from: d)
    #expect(mixed.library.selectedID == "lawyer")
    #expect(mixed.library.selected.promptName == "律师")
    #expect(mixed.library.customs.count == 1)
}

@Test func deletingTheSelectedCustomFallsBackWithoutTouchingOthers() {
    var library = ProfessionLibrary(customs: [], selectedID: "sales")
    #expect(library.add(name: "第一项", prompt: "留意甲") == nil)
    let first = library.selectedID
    #expect(library.add(name: "第二项", prompt: "留意乙") == nil)
    let second = library.selectedID
    let removedSecond = library.delete(id: second)
    #expect(removedSecond)
    #expect(library.selectedID == "general")
    #expect(library.selected.promptName == "通用")
    #expect(library.customs.map(\.id) == [first])
}

@Test func corruptCustomRowsAreSkipped() {
    let d = defaults()
    d.set("student", forKey: "profession")
    d.set([
        ["id": "general", "label": "不该盖住预设", "prompt": "忽略"],
        ["id": "", "label": "空", "prompt": "忽略"],
        ["id": "ok-1", "label": "", "prompt": "没有名称"],
        ["id": "ok-2", "label": "研究员助理", "prompt": ""],
        ["id": "ok-3", "label": "研究员助理", "prompt": "留意还没核实的出处。"],
    ], forKey: ProfessionLibrary.customKey)
    let loaded = ProfessionLibrary.load(from: d)
    #expect(loaded.library.customs.map(\.id) == ["ok-3"])
    #expect(loaded.library.selectedID == "student")
    #expect(loaded.library.selected.builtin)
}

@Test func settingsDetailKeepsBuiltinFocusAndShortensCustomPrompt() {
    let founder = SelectedProfession(builtin: .founder)
    #expect(founder.settingsDetail == founder.focus)
    var library = ProfessionLibrary(customs: [], selectedID: "general")
    #expect(library.add(name: "编辑", prompt: "第一行\n第二行还要留意引用") == nil)
    #expect(library.selected.settingsDetail == "第一行 第二行还要留意引用")
    let long = String(repeating: "留意", count: 40)
    #expect(library.add(name: "长提示", prompt: long) == nil)
    #expect(library.selected.settingsDetail.count == 73)
    #expect(library.selected.settingsDetail.hasSuffix("…"))
}

@Test func analysisPromptKeepsProfessionSlotAndEveryScene() {
    let guide = sceneGuide()
    let chinese = "全部用简体中文。"
    let title = "一句话标题，不超过 18 个字"
    for row in builtinPrompts {
        let text = SelectedProfession(builtin: Profession(rawValue: row.0)!).analysisSystem(
            fixedSceneCode: nil, sceneGuide: guide, titleHint: title, notesRule: chinese)
        #expect(text.hasPrefix("你是录音整理助手。使用者的职业是「\(row.1)」，\(row.2)\n"))
        #expect(text.contains("\n先判断场景，从下面的英文代号里选一个。\n" + guide + "\n"))
        #expect(!text.contains("场景已经确定是"))
    }

    let sales = SelectedProfession(builtin: .sales).analysisSystem(
        fixedSceneCode: "sales", sceneGuide: guide, titleHint: title, notesRule: chinese)
    #expect(sales.contains("场景已经确定是 sales，不要改。"))
    #expect(!sales.contains("先判断场景"))
    for code in ["meeting", "interview", "sales"] {
        let text = SelectedProfession(builtin: .founder).analysisSystem(
            fixedSceneCode: code, sceneGuide: guide, titleHint: title, notesRule: chinese)
        #expect(text.contains("场景已经确定是 \(code)，不要改。"))
        #expect(text.contains(guide))
    }
    for row in sceneRows {
        #expect(sales.contains(row.0))
        #expect(sales.contains(row.1))
        for heading in row.3 { #expect(sales.contains(heading)) }
    }
    let professionAt = sales.range(of: "使用者的职业是")!
    let sceneAt = sales.range(of: "场景已经确定是 sales")!
    let jsonAt = sales.range(of: "\"scene\"")!
    #expect(professionAt.lowerBound < sceneAt.lowerBound && sceneAt.lowerBound < jsonAt.lowerBound)
    #expect(sales.contains("\"title\": \"一句话标题，不超过 18 个字，说清这段录音是什么事\""))
    #expect(sales.hasSuffix("- \(chinese)"))

    let english = SelectedProfession(builtin: .general).analysisSystem(
        fixedSceneCode: nil, sceneGuide: guide,
        titleHint: "一句话英文标题，不超过 10 个单词", notesRule: "全部用英文（English）写：title、summary。")
    #expect(english.contains("\"title\": \"一句话英文标题，不超过 10 个单词，说清这段录音是什么事\""))
    #expect(english.contains("全部用英文（English）写：title、summary。"))
    #expect(!english.contains("一句话标题，不超过 18 个字"))

    var library = ProfessionLibrary(customs: [], selectedID: "general")
    #expect(library.add(name: "开源维护者", prompt: "格外留意兼容性、破坏性改动和发行说明。") == nil)
    let custom = library.selected.analysisSystem(fixedSceneCode: nil, sceneGuide: guide, titleHint: title, notesRule: chinese)
    #expect(custom.hasPrefix("你是录音整理助手。使用者的职业是「开源维护者」，格外留意兼容性、破坏性改动和发行说明。\n"))
    #expect(custom.contains(guide))
    #expect(custom.contains("先判断场景，从下面的英文代号里选一个。"))
    #expect(custom.contains("客户需求") && custom.contains("值得追问") && custom.contains("知识点"))
}

@Test func sceneGuideLineMatchesTheExistingSentence() {
    #expect(SelectedProfession.sceneGuideLine(
        code: "sales", name: "销售",
        definition: "向客户介绍产品、谈价格、处理异议、推进成交",
        headings: ["客户需求", "顾虑与异议", "预算与决策人", "下一步"])
        == "- sales（销售）：向客户介绍产品、谈价格、处理异议、推进成交。栏目：客户需求、顾虑与异议、预算与决策人、下一步")
    #expect(SelectedProfession.sceneGuideLine(
        code: "meeting", name: "会议",
        definition: "多人围绕议题讨论并形成决定的内部会议、例会、评审",
        headings: ["结论与决定", "讨论要点", "分歧与风险"])
        == "- meeting（会议）：多人围绕议题讨论并形成决定的内部会议、例会、评审。栏目：结论与决定、讨论要点、分歧与风险")
    #expect(SelectedProfession.sceneGuideLine(
        code: "interview", name: "访谈",
        definition: "一方提问一方回答：采访、用户访谈、面试、调研",
        headings: ["核心观点", "原话金句", "值得追问"])
        == "- interview（访谈）：一方提问一方回答：采访、用户访谈、面试、调研。栏目：核心观点、原话金句、值得追问")
}

@Test func rewriteUsesBuiltinNameOnlyAndCustomPrompt() {
    let teacher = SelectedProfession(builtin: .teacher).rewriteSystem(instruction: "改成一封邮件")
    #expect(teacher == """
    你是一位文字编辑。使用者的职业是「教师与培训师」。下面是他一段录音的内容，请按要求改写。
    要求：改成一封邮件
    只用录音里有的事实、观点和例子，不要编造数据或经历。录音里的口语垫词不要带进成品。
    直接输出成品，不要解释你做了什么。
    """)
    #expect(!teacher.contains("格外留意"))

    var library = ProfessionLibrary(customs: [], selectedID: "teacher")
    #expect(library.add(name: "开源维护者", prompt: "格外留意兼容性和发行说明。") == nil)
    let custom = library.selected.rewriteSystem(instruction: "改成发布说明")
    #expect(custom.hasPrefix("你是一位文字编辑。使用者的职业是「开源维护者」，格外留意兼容性和发行说明。\n下面是他一段录音的内容，请按要求改写。\n"))
    #expect(custom.contains("要求：改成发布说明"))
    #expect(custom.contains("不要编造数据或经历"))
}

@Test func fullAnalysisTemplateStaysByteForByte() {
    let guide = "- meeting（会议）：定义。栏目：结论与决定"
    let text = SelectedProfession(builtin: .founder).analysisSystem(
        fixedSceneCode: nil, sceneGuide: guide,
        titleHint: "一句话标题，不超过 18 个字", notesRule: "全部用简体中文。")
    #expect(text == """
    你是录音整理助手。使用者的职业是「创业者与管理者」，格外留意决策、资源分配、风险、人事和需要亲自跟进的事。

    先判断场景，从下面的英文代号里选一个。
    - meeting（会议）：定义。栏目：结论与决定

    然后只输出一个 JSON 对象，不要任何别的文字：
    {
      "scene": "场景的英文代号",
      "title": "一句话标题，不超过 18 个字，说清这段录音是什么事",
      "summary": "两到四句话的摘要，先说结论",
      "sections": [{"heading": "所选场景的栏目名", "items": ["这一栏下的要点，每条一句完整的话"]}],
      "todos": ["后续要做的事，写清谁、做什么、什么时候；没有就给空数组"],
      "tags": ["2 到 5 个主题标签，名词，不带 #"],
      "people": ["出现的人名或称呼；没有就给空数组"]
    }

    要求：
    - sections 必须使用所选场景的栏目名，某一栏没有内容就不要输出这一栏。
    - 只写录音里真有的内容。数字、金额、日期、人名照原样写，听不清的不要猜。
    - 全部用简体中文。
    """)
}
