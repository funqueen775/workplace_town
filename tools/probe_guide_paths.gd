extends Node

## 首月带巡每一段引导线的离路检查：把网格寻路的结果按 8px 采样，
## 只要有一个采样点不在通行遮罩上（含 14px 余量），就报出来。

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
	var legs := [
		["出发点 → A 区", Vector2(455, 500), Vector2(464, 272)],
		["A 区 → 心湖步道", Vector2(464, 272), Vector2(860, 770)],
		["心湖步道 → B 区工位", Vector2(860, 770), Vector2(1008, 240)],
		["B 区工位 → A 区周会", Vector2(1008, 240), Vector2(464, 272)],
		# 故意把终点丢进湖里：落点必须自己吸回岸边，线也不能穿水。
		["（对照）终点丢在湖心", Vector2(464, 272), Vector2(960, 700)],
	]
	for leg in legs:
		var path := _grid.route(leg[1], leg[2])
		var bad := 0
		var worst := ""
		for index in path.size() - 1:
			var from: Vector2 = path[index]
			var to: Vector2 = path[index + 1]
			var steps := maxi(2, int(from.distance_to(to) / 8.0))
			for step in steps + 1:
				var point: Vector2 = from.lerp(to, float(step) / float(steps))
				if not _clear(point):
					bad += 1
					if worst.is_empty():
						worst = "(%d, %d)" % [roundi(point.x), roundi(point.y)]
		var last: Vector2 = path[path.size() - 1]
		print("%-22s 折点 %2d 段 %2d · 终点 (%d, %d) · 离路采样 %d %s" % [
			String(leg[0]), path.size(), path.size() - 1, roundi(last.x), roundi(last.y), bad,
			("首个离路点 " + worst) if bad > 0 else "",
		])
	get_tree().quit()


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
