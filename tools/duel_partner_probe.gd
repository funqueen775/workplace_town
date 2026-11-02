extends Node

## 两条线各拉一次对局页，把界面上能看见的字全抓下来对一遍：
##   旧 48 个月那条线（什么都不设）→ 应该还是王哥带队、赢了说"紧急通道/码头"；
##   十二个月那条线（按 m7_valley 的 duelText 设）→ 应该全程是小赵，不再出现码头。
## 用法：<godot> --path . --resolution 1600x900 res://tools/duel_partner_probe.tscn

const SCENE := "res://training_valley/main.tscn"
const OUT_DIR := "res://test_artifacts/duel"
const BANNED := ["王哥", "紧急通道", "码头", "创意水港"]

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.0).timeout
	var start: Variant = _town.get("_month12_start_panel")
	if start != null and is_instance_valid(start) and bool(start.call("is_open")):
		_town.call("_on_month_start_continued")
		await get_tree().create_timer(1.0).timeout
	_town.call("debug_jump_to_month", 7)
	await get_tree().create_timer(1.6).timeout
	# 跳月又会压一张月首卡在顶上：先收掉，不然是拿探针自己造的重叠去拍照。
	for i in 20:
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.6).timeout
			break
		await get_tree().create_timer(0.3).timeout

	await _sweep("旧线", {})
	await _sweep("十二个月", _duel_text_from_data())

	print("PARTNER_PROBE_DONE")
	_done = true
	get_tree().quit(0)


## 把活动数据里那一份台词包原样读出来（探针不抄第二份，省得改了数据探针还在演旧的）。
func _duel_text_from_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/v12m/activities.json"))
	var list: Array = parsed if parsed is Array else (parsed as Dictionary).get("activities", [])
	for value in list:
		var act := Dictionary(value)
		if String(act.get("id", "")) == "m7_valley":
			return act.get("duelText", {}) as Dictionary
	return {}


func _sweep(tag: String, duel_text: Dictionary) -> void:
	var battle: Control = load(SCENE).instantiate()
	# 顺序和城镇里那个入口一致：先把搭档与台词设好，再进树。
	# 反过来（先 add_child 再 set）整页界面已经用默认值建好了，改也改不回来——探针踩过一次。
	if not duel_text.is_empty():
		battle.set("skip_intro", true)
		battle.set("allow_leave_on_defeat", true)
		battle.set("partner_name", String(duel_text.get("partner", "王哥")))
		var art := String(duel_text.get("partnerArt", ""))
		if not art.is_empty():
			battle.set("partner_texture", load(art))
		battle.set("select_line", String(duel_text.get("selectLine", "")))
		battle.set("victory_dialogue", duel_text.get("victoryLines", []) as Array)
		battle.set("victory_end_title", String(duel_text.get("endTitle", "")))
		battle.set("victory_end_text", String(duel_text.get("endText", "")))
	add_child(battle)
	await get_tree().create_timer(1.2).timeout
	print("== ", tag, " · 选搭档页 ==")
	_dump(battle)
	_shot(battle, "搭档_%s_选搭档.png" % tag)
	# 进对局：选带队那位，再把开场那两步教学点掉。
	battle.call("_select_wang")
	await get_tree().create_timer(0.8).timeout
	battle.call("_advance_dialogue")
	await get_tree().create_timer(0.6).timeout
	battle.call("_advance_dialogue")
	await get_tree().create_timer(0.8).timeout
	print("== ", tag, " · 对局中 ==")
	_dump(battle)
	_shot(battle, "搭档_%s_对局.png" % tag)
	# 直接落到胜利那一段，看台词与收束卡。
	battle.call("_finish_victory")
	await get_tree().create_timer(0.8).timeout
	print("== ", tag, " · 胜利三句 ==")
	for line in (battle.get("dialogue_lines") as Array):
		print("   ", String(Dictionary(line).get("speaker", "")), "：", String(Dictionary(line).get("text", "")))
	_shot(battle, "搭档_%s_胜利.png" % tag)
	battle.call("_advance_dialogue")
	await get_tree().create_timer(0.4).timeout
	battle.call("_advance_dialogue")
	await get_tree().create_timer(0.4).timeout
	battle.call("_advance_dialogue")
	await get_tree().create_timer(0.8).timeout
	print("== ", tag, " · 收束卡 ==")
	print("   标题：", String(battle.get("end_title").text))
	print("   正文：", String(battle.get("end_text").text).replace("\n", " / "))
	_shot(battle, "搭档_%s_收束.png" % tag)
	battle.queue_free()
	await get_tree().create_timer(0.5).timeout


func _dump(root: Node) -> void:
	var hits := 0
	for node in _all_children(root):
		var shown := _shown_text(node)
		if shown.is_empty():
			continue
		for word in BANNED:
			if shown.find(word) >= 0:
				print("   ! 界面上还有「", word, "」：", shown)
				hits += 1
				break
	print("   带旧词的行：", hits)


func _shown_text(node: Node) -> String:
	if node is Label:
		var label := node as Label
		if not label.visible:
			return ""
		return label.text
	if node is Button:
		var button := node as Button
		if not button.visible:
			return ""
		return button.text
	return ""


func _all_children(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var node := stack.pop_back() as Node
		for child in node.get_children():
			stack.append(child)
			out.append(child)
	return out


func _shot(root: Node, file_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return
	image.save_png(OUT_DIR + "/" + file_name)


func _watchdog() -> void:
	await get_tree().create_timer(240.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
