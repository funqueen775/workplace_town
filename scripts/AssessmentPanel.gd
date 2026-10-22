class_name AssessmentPanel
extends CanvasLayer

signal continued(month: int)

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PASS_LINES := {
	6: "老周：第一个台阶。别站在上面回头太久。",
	12: "王哥：以后会有一块模块真的归你。不是帮忙，是负责。",
	18: "系统：晋升通过。告警灯还亮着，没人有空当场庆祝。",
	24: "老周：从今天起，你给出的不只是建议。出了结果，也会先找你。",
	30: "老周：你开始碰到公司不愿意写进周报的问题了。职位也该跟上。",
	36: "老周：以后你汇报的不只是自己做了什么，还要说清团队为什么做得到。",
	42: "系统：晋升通过。结果没有替你撤回任何已经说出口的话。",
}
const FAIL_LINES := {
	6: "老周：这次没过。不是清零，东西还在。下个考核窗继续拿出来说话。",
	12: "王哥：没升不等于没长。把这次卡住你的地方记下来，别只记结果。",
	18: "系统：本次未晋升。王哥只发来一句：先把今晚救完，明天再难过。",
	24: "老周：你能做事，但还没证明你能让别人放心把事交给你。下次继续。",
	30: "老周：能看见问题不够。你还要证明自己能把问题推到该去的地方。",
	36: "老周：你已经在做高一级的事，但证据还不够稳定。别把这句话当安慰。",
	42: "系统：本次未晋升。你仍要带着刚才的选择走完剩下六个月。",
}

var _month := 0
var _ready_to_continue := false
var _title: Label
var _status: Label
var _continue_button: Button
var _continue_unconfirmed_button: Button
var _actions: HBoxContainer


func _ready() -> void:
	layer = 205
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.05, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_top = -170
	panel.offset_right = 420
	panel.offset_bottom = 170
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eee0")
	style.border_color = Color("9d7946")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	_title = _label("", 30)
	content.add_child(_title)
	_status = _label("", 22)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 110
	content.add_child(_status)
	_continue_button = Button.new()
	_continue_button.text = "继续"
	_continue_button.custom_minimum_size = Vector2(160, 48)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.add_theme_font_override("font", FONT)
	_continue_button.add_theme_font_size_override("font_size", 20)
	_continue_button.pressed.connect(_on_button_pressed)
	_continue_unconfirmed_button = Button.new()
	_continue_unconfirmed_button.text = "结果待确认，仍继续流程"
	_continue_unconfirmed_button.custom_minimum_size = Vector2(260, 48)
	_continue_unconfirmed_button.add_theme_font_override("font", FONT)
	_continue_unconfirmed_button.add_theme_font_size_override("font_size", 18)
	_continue_unconfirmed_button.pressed.connect(_on_continue_unconfirmed_pressed)
	_continue_unconfirmed_button.hide()
	_actions = HBoxContainer.new()
	_actions.alignment = BoxContainer.ALIGNMENT_END
	_actions.add_theme_constant_override("separation", 12)
	content.add_child(_actions)
	_actions.add_child(_continue_unconfirmed_button)
	_actions.add_child(_continue_button)
	ApiClient.assessment_ready.connect(_on_assessment_ready)
	ApiClient.assessment_failed.connect(_on_assessment_failed)


func open(month: int) -> void:
	_month = month
	_ready_to_continue = false
	_title.text = "第 %d 月 · 晋升检查" % month
	visible = true
	if ApiClient.is_live_mode():
		_status.text = "过去六个月的工作正在结算。你可以等待结果，也可以先继续后续流程；晋升结果尚未确认。"
		_continue_button.disabled = true
		_continue_unconfirmed_button.show()
		ApiClient.request_assessment(month)
	else:
		_status.text = "当前未连接后端，晋升结果暂不显示。继续主线不会伪造通过或失败。"
		_ready_to_continue = true
		_continue_button.disabled = false
		_continue_unconfirmed_button.hide()


func _on_assessment_ready(result: Dictionary) -> void:
	if not visible or int(result.get("month", 0)) != _month:
		return
	var passed := bool(result.get("passed", false))
	_title.text = "第 %d 月 · %s" % [_month, "晋升通过" if passed else "本次未晋升"]
	_status.text = PASS_LINES[_month] if passed else FAIL_LINES[_month]
	var summary: Dictionary = result.get("assessmentSummary", {})
	if not passed and not summary.is_empty():
		var reasons: Array[String] = []
		if not bool(summary.get("cumulativePassed", true)):
			reasons.append("本期成长与交付积累还不够")
		if not bool(summary.get("behaviorPassed", true)):
			reasons.append("关键选择触及诚信边界")
		if not bool(summary.get("defensePassed", true)):
			reasons.append("答辩表现尚未达标")
		if not reasons.is_empty():
			_status.text += "\n考核反馈：%s。" % "、".join(reasons)
	var evidence: Dictionary = result.get("interactionEvidence", {})
	if not evidence.is_empty():
		_status.text += "\n本期记录：%d 次自由行动、%d 次 NPC 对话、%d 场训练。" % [
			int(evidence.get("actionCount", 0)), int(evidence.get("dialogueCount", 0)),
			(evidence.get("trainingResults", []) as Array).size(),
		]
	_ready_to_continue = true
	_continue_button.text = "继续"
	_continue_button.disabled = false
	_continue_unconfirmed_button.hide()


func _on_assessment_failed(reason: String) -> void:
	if not visible:
		return
	_status.text = reason
	_continue_button.text = "重试"
	_continue_button.disabled = false
	_continue_unconfirmed_button.show()


func _on_button_pressed() -> void:
	if _ready_to_continue:
		visible = false
		continued.emit(_month)
	elif ApiClient.is_live_mode():
		_continue_button.disabled = true
		_status.text = "正在重新结算。"
		_continue_unconfirmed_button.hide()
		ApiClient.request_assessment(_month)


func _on_continue_unconfirmed_pressed() -> void:
	visible = false
	continued.emit(_month)


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("3b2e22"))
	return label
