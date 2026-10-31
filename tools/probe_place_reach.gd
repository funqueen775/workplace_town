extends Node

## 「这扇门玩家到底走不走得到」探针。
##
## 立门之前先跑这个：门点本身通不通、从上一个剧情落点铺不铺得出黄线。
## 第 2 月那扇图书馆的门就是靠它定位置的——门口压在非通行点上，
## 玩家走到线尽头也按不进门，整月就卡死了。
##
## 用法：<godot> --path <PROJ> --headless res://tools/probe_place_reach.tscn

const MASK_PATH := "res://assets/town/walkability_mask.png"
const WORLD_SIZE := Vector2(1920, 1080)
const CLEARANCE := 14.0

var _grid := TownWalkGrid.new()
var _image: Image


func _ready() -> void:
	_image = load(MASK_PATH).get_image()
	if not _grid.build(_image, WORLD_SIZE):
		print("GRID BUILD FAILED")
		get_tree().quit()
		return
	var points := {
		"A评审室": Vector2(416, 241),
		"A区门口": Vector2(464, 272),
		"B工位": Vector2(1008, 240),
		"C水巷": Vector2(1424, 273),
		"D区入口": Vector2(1446, 737),
		"D区内侧": Vector2(1240, 740),
		"D牌下": Vector2(1586, 652),
		"D广场A": Vector2(1560, 640),
		"D广场B": Vector2(1520, 700),
		"D广场C": Vector2(1460, 700),
		"心湖": Vector2(860, 770),
	}
	for name in points:
		var p: Vector2 = points[name]
		var snap: Vector2 = _grid.nearest_walkable(p)
		print("%-8s (%4d,%4d) %s 吸附→(%4d,%4d) 偏移 %5.1f" % [
			name, roundi(p.x), roundi(p.y),
			"通" if _clear(p) else "不通",
			roundi(snap.x), roundi(snap.y), p.distance_to(snap),
		])
	var legs := [
		["A区门口 → D区入口", Vector2(464, 272), Vector2(1446, 737)],
		["B工位 → D区入口", Vector2(1008, 240), Vector2(1446, 737)],
		["C水巷 → D区入口", Vector2(1424, 273), Vector2(1446, 737)],
		["D区入口 → B工位", Vector2(1446, 737), Vector2(1008, 240)],
		["B工位 → D区内侧", Vector2(1008, 240), Vector2(1240, 740)],
		# 图书馆那扇门的候选：D 牌底下那一圈广场，逐个试能不能从 A 区评审室走到。
		["A区门口 → D牌下(1586,652)", Vector2(464, 272), Vector2(1586, 652)],
		["A区门口 → D广场(1560,640)", Vector2(464, 272), Vector2(1560, 640)],
		["A区门口 → D广场(1520,700)", Vector2(464, 272), Vector2(1520, 700)],
		["A区门口 → D广场(1460,700)", Vector2(464, 272), Vector2(1460, 700)],
		["A区门口 → D广场(1600,600)", Vector2(464, 272), Vector2(1600, 600)],
	]
	for leg in legs:
		var path := _grid.route(leg[1], leg[2])
		if path.is_empty():
			print("%-18s 走不通（寻路返回空）" % String(leg[0]))
			continue
		var bad := 0
		for index in path.size() - 1:
			var from: Vector2 = path[index]
			var to: Vector2 = path[index + 1]
			var steps := maxi(2, int(from.distance_to(to) / 8.0))
			for step in steps + 1:
				if not _clear(from.lerp(to, float(step) / float(steps))):
					bad += 1
		print("%-18s 折点 %2d · 终点 (%d, %d) · 离路采样 %d" % [
			String(leg[0]), path.size(),
			roundi((path[path.size() - 1] as Vector2).x), roundi((path[path.size() - 1] as Vector2).y), bad,
		])
	_scan("--scan" in OS.get_cmdline_user_args() or "--library" in OS.get_cmdline_user_args())
	get_tree().quit()


## 门点不能照着 regions.json 的 entrance 摆：那个点是给旧 48 个月用的，
## 压在房子或窄路上，寻路（带侵蚀）根本到不了。这一片扫一遍，
## 把"从上一个剧情落点真能走到"的点画出来，门就挑离房子最近的那一个。
func _scan(enabled: bool) -> void:
	if not enabled:
		return
	var from := Vector2(464, 272) if "--library" in OS.get_cmdline_user_args() else Vector2(1008, 240)
	var box := [1480, 660, 1900, 980] if "--library" in OS.get_cmdline_user_args() else [1120, 520, 1800, 940]
	print("---- 从 (%d, %d) 能不能走到（. 走不通 / o 走得通）----" % [roundi(from.x), roundi(from.y)])
	var header := "        "
	for x in range(box[0], box[2], 100):
		header += "%-5d" % x
	print(header)
	for y in range(box[1], box[3], 20):
		var row := "y=%4d " % y
		for x in range(box[0], box[2], 20):
			row += "o" if not _grid.route(from, Vector2(x, y)).is_empty() else "."
		print(row)


func _clear(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(-CLEARANCE, 0), Vector2(CLEARANCE, 0), Vector2(0, -CLEARANCE), Vector2(0, CLEARANCE)]:
		var sample: Vector2 = point + offset
		if sample.x < 0.0 or sample.y < 0.0 or sample.x >= WORLD_SIZE.x or sample.y >= WORLD_SIZE.y:
			return false
		var x := clampi(int(sample.x), 0, _image.get_width() - 1)
		var y := clampi(int(sample.y), 0, _image.get_height() - 1)
		var pixel := _image.get_pixel(x, y)
		if pixel.a < 0.5 or pixel.r < 0.5:
			return false
	return true
