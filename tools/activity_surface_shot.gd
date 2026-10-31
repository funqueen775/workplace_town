extends Node

## 同一个 E 区，两种摆法各拍一张，给玩家挑：
##   屋里 —— 走进区里，右上角一叠整卡压在室内画面上（队友 10-30 录屏那版）；
##   整屏 —— 进门弹一整屏卡片列表（票根，字全部现读数据）。
## 用法：<godot> --path . --resolution 1600x900 res://tools/activity_surface_shot.tscn -- --no-resume

const OUT_DIR := "res://test_artifacts/activity_cards"
const INTERIORS := {
	"A": "res://assets/八大区域地图重制版/A_市场部.png",
	"B": "res://assets/八大区域地图重制版/B_研发部.png",
	"C": "res://assets/八大区域地图重制版/C_销售部.png",
	"D": "res://assets/八大区域地图重制版/D_人事部.png",
	"E": "res://assets/场景内部图/松风训练谷.png",
	"F": "res://assets/场景内部图/观澜展会码头.png",
	"G": "res://assets/场景内部图/暖邻康护院.png",
	"H": "res://assets/场景内部图/慢生活园.png",
}

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.2).timeout
	var start = _town.get("_month12_start_panel")
	for i in 60:
		await get_tree().create_timer(0.1).timeout
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.8).timeout
			break
	var unlocked: Dictionary = _town.get("_month12_unlocked_places")
	for act in (_town.get("_month12_places") as Array):
		unlocked[String(Dictionary(act).get("id", ""))] = true
	# 先把还在播的剧情屏收掉：它的黑场会把屋里那一叠压在下面（实拍踩过）。
	var story = _town.get("_story_event_panel")
	if story != null and is_instance_valid(story):
		story.call("dismiss")
		await get_tree().create_timer(0.4).timeout
	var hud = _town.get("_town_ui_v2")
	var zones: Array = _town.get("ZONES")
	for zone_code in ["A", "B", "C", "D", "E", "F", "G", "H"]:
		var zone: Dictionary = {}
		for value in zones:
			if String(Dictionary(value).get("code", "")) == zone_code:
				zone = Dictionary(value)
				break
		_town.set("_active_zone", zone)
		# 真进区时城镇会先把右上角"本月主线"收掉，探针照做一遍，
		# 不然拍出来是探针自己造的重叠，游戏里看不到。
		if hud != null and is_instance_valid(hud):
			hud.call("set_activity_scene_mode", true)
		var preview = _town.get("_interior_preview")
		if zone_code in ["A", "B", "C", "D"]:
			preview.call("use_department_layout", true)
		else:
			preview.call("use_activity_layout", false)
		preview.call("present", zone, String(INTERIORS[zone_code]))
		await get_tree().create_timer(0.8).timeout
		_town.call("_show_month12_place_list", zone_code)
		await get_tree().create_timer(0.9).timeout
		var cards = _town.get("_activity_cards")
		var lit := 0
		for button in (preview.get("_activity_buttons") as Array):
			var ctrl := button as Control
			if ctrl != null and ctrl.visible:
				lit += 1
		var drawn: int = (preview.get("_drawn_cards") as Array).size()
		var panel = _town.get("_activity_panel")
		print("[surface] ", zone_code, " 区：整卡=", lit, " 现画票根=", drawn,
			" 美术底板=", bool((preview.get("_activity_board") as CanvasItem).visible),
			" 现画底板=", bool((preview.get("_board_live") as CanvasItem).visible),
			" 右下角面板可见=", (panel != null and is_instance_valid(panel) and bool(panel.get("visible"))),
			" 整屏列表开着=", bool(cards.call("is_open")))
		await _shot("摆法_%s区" % zone_code)
		if bool(cards.call("is_open")):
			cards.call("close")
		await get_tree().create_timer(0.3).timeout
	# 再拍整屏那版：直接叫列表组件开，不改代码里的那个开关。
	# 再拍整屏那版：直接叫列表组件开，不改代码里的那个开关。
	var preview2 = _town.get("_interior_preview")
	var cards2 = _town.get("_activity_cards")
	preview2.call("set_activities", [], true, 1)
	cards2.call("open", "E 区", _rows_for("E"), "本月还剩 1 格")
	await get_tree().create_timer(0.7).timeout
	print("[surface] 整屏：列表开着=", bool(cards2.call("is_open")))
	print("SURFACE_SHOT_DONE")
	_done = true
	get_tree().quit(0)


## 和 _show_month12_place_list 同一批数据，只是不等那个开关。
func _rows_for(zone_code: String) -> Array:
	var rows: Array = []
	for value in _town.get("_month12_places"):
		if not (value is Dictionary):
			continue
		var act := Dictionary(value)
		if String(act.get("locationId", "")) != zone_code:
			continue
		var pid := String(act.get("id", ""))
		if not bool((_town.get("_month12_unlocked_places") as Dictionary).has(pid)):
			continue
		rows.append({
			"id": pid,
			"title": String(act.get("name", "自由活动")),
			"cardArt": String(act.get("cardArt", "")),
			"badge": String(_town.call("_month12_zone_name", zone_code)),
			"cost": int(act.get("hCost", 0)),
			"note": String(_town.call("_month12_place_row_note", act)),
		})
	return rows


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
