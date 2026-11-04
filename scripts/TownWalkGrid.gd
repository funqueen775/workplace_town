class_name TownWalkGrid
extends RefCounted

## 小镇步行网格：直接从道路通行遮罩算出来，给引导线寻路和落点吸附用。
##
## 为什么不用 navigation.json 里那几个大矩形：那批矩形是为了"传送门落在哪"画的，
## 面积粗，心湖那一块整个被 h_forecourt 罩住。首月带巡拿它的中心当落点，
## 结果就是引导终点落进水里、黄线斜穿湖面。遮罩才是玩家真正能走的那层皮。

## 一格 32 世界像素：1920×1080 → 60×34 ≈ 2000 格，一次 A* 完全无压力。
const CELL := 32
## 判定一格能不能用：中心 + 四角（±20px）都要是路。等于把可走区往里收 20px，
## 引导线和落点就离湖沿、墙根留出一条肉眼看得见的缝，不会压着水边画。
const EROSION := 20.0
## 连线抽稀时，沿线的采样半径：保证简化后的折线仍然压在路上。
const CLEARANCE := 20.0

var _cols := 0
var _rows := 0
var _open := PackedByteArray()
var _image: Image


func build(image: Image, world_size: Vector2) -> bool:
	if image == null or image.is_empty():
		return false
	_image = image
	_cols = maxi(1, int(world_size.x) / CELL)
	_rows = maxi(1, int(world_size.y) / CELL)
	_open.resize(_cols * _rows)
	for row in _rows:
		for col in _cols:
			_open[row * _cols + col] = 1 if _cell_walkable(col, row) else 0
	return true


func is_ready() -> bool:
	return _cols > 0 and _rows > 0 and not _open.is_empty()


## 最近的可走格中心：带巡落点、传送门出口这类"必须踩在地上"的坐标都走它。
func nearest_walkable(point: Vector2) -> Vector2:
	if not is_ready():
		return point
	var center := Vector2(_cols, _rows) * 0.5
	if _is_walkable_world(point):
		return point
	var best := _cell_center(_cols / 2, _rows / 2)
	var best_distance := INF
	for row in _rows:
		for col in _cols:
			if _open[row * _cols + col] == 0:
				continue
			var candidate := _cell_center(col, row)
			var distance := candidate.distance_squared_to(point)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best


## 起点 → 终点的折线（世界坐标）。走不通就返回空数组，让调用方退回旧算法。
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not is_ready():
		return PackedVector2Array()
	var start := _clamp_to_cell(from)
	var goal := _clamp_to_cell(to)
	if _open[goal.y * _cols + goal.x] == 0:
		goal = _nearest_cell(to)
	if _open[start.y * _cols + start.x] == 0:
		start = _nearest_cell(from)
	if _open[start.y * _cols + start.x] == 0 or _open[goal.y * _cols + goal.x] == 0:
		return PackedVector2Array()
	var chain := _astar(start, goal)
	if chain.is_empty():
		return PackedVector2Array()
	var path := PackedVector2Array()
	for cell in chain:
		path.append(_cell_center(cell.x, cell.y))
	# 真实首尾接上后再整体拉直一遍：只在"这段确实全压在路上"时才合并折点。
	# 端点本身踩在路上才用原坐标，否则退到最近的可走点 —— 宁可光环离门差一步，
	# 也不能让引导线最后一段斜穿湖面。
	path.insert(0, from if _is_walkable_world(from) else nearest_walkable(from))
	path.append(to if _is_walkable_world(to) else nearest_walkable(to))
	path = _string_pull(path)
	return _drop_collinear(path)


func _cell_walkable(col: int, row: int) -> bool:
	var center := _cell_center(col, row)
	for offset in [Vector2.ZERO, Vector2(-EROSION, -EROSION), Vector2(EROSION, -EROSION), Vector2(-EROSION, EROSION), Vector2(EROSION, EROSION)]:
		if not _mask_at(center + offset):
			return false
	return true


func _mask_at(point: Vector2) -> bool:
	if _image == null:
		return false
	var x := clampi(int(point.x * float(_image.get_width()) / (float(_cols) * CELL)), 0, _image.get_width() - 1)
	var y := clampi(int(point.y * float(_image.get_height()) / (float(_rows) * CELL)), 0, _image.get_height() - 1)
	var pixel := _image.get_pixel(x, y)
	return pixel.a >= 0.5 and pixel.r >= 0.5


func _is_walkable_world(point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(-CLEARANCE, 0), Vector2(CLEARANCE, 0), Vector2(0, -CLEARANCE), Vector2(0, CLEARANCE)]:
		if not _mask_at(point + offset):
			return false
	return true


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2(float(col) + 0.5, float(row) + 0.5) * float(CELL)


func _clamp_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x / CELL), 0, _cols - 1), clampi(int(point.y / CELL), 0, _rows - 1))


func _nearest_cell(point: Vector2) -> Vector2i:
	var snapped := nearest_walkable(point)
	return Vector2i(clampi(int(snapped.x / CELL), 0, _cols - 1), clampi(int(snapped.y / CELL), 0, _rows - 1))


func _open_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _cols and cell.y < _rows and _open[cell.y * _cols + cell.x] == 1


## 八邻域 A*；斜走要求两侧正交格都可走，避免从墙角挤过去。
func _astar(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_list: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {start: 0.0}
	while not open_list.is_empty():
		var best_index := 0
		var best_score: float = _score(open_list[0], goal) + float(cost_so_far[open_list[0]])
		for index in open_list.size():
			var score: float = _score(open_list[index], goal) + float(cost_so_far[open_list[index]])
			if score < best_score:
				best_score = score
				best_index = index
		var current: Vector2i = open_list[best_index]
		open_list.remove_at(best_index)
		if current == goal:
			return _rebuild(came_from, current)
		for step in [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
		]:
			var next: Vector2i = current + step
			if not _open_cell(next):
				continue
			if absi(step.x) == 1 and absi(step.y) == 1:
				if not _open_cell(Vector2i(next.x, current.y)) or not _open_cell(Vector2i(current.x, next.y)):
					continue
			var step_cost := 1.4142 if (absi(step.x) + absi(step.y)) == 2 else 1.0
			var new_cost: float = cost_so_far[current] + step_cost
			if cost_so_far.has(next) and cost_so_far[next] <= new_cost:
				continue
			cost_so_far[next] = new_cost
			came_from[next] = current
			if not open_list.has(next):
				open_list.append(next)
	return []


func _score(from: Vector2i, to: Vector2i) -> float:
	var dx := absi(from.x - to.x)
	var dy := absi(from.y - to.y)
	return maxf(float(dx), float(dy)) + 0.4142 * minf(float(dx), float(dy))


func _rebuild(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path


## 能看见就直接连：把一格一格的折线拉成贴着路走的少数几段。
func _string_pull(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() < 3:
		return path
	var result := PackedVector2Array([path[0]])
	var index := 0
	while index < path.size() - 1:
		var next := path.size() - 1
		while next > index + 1:
			if _segment_clear(path[index], path[next]):
				break
			next -= 1
		result.append(path[next])
		index = next
	return result


func _segment_clear(from: Vector2, to: Vector2) -> bool:
	var distance := from.distance_to(to)
	var steps := maxi(2, int(distance / 8.0))
	for step in steps + 1:
		var point := from.lerp(to, float(step) / float(steps))
		if not _is_walkable_world(point):
			return false
	return true


func _drop_collinear(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() < 3:
		return path
	var result := PackedVector2Array([path[0]])
	for index in range(1, path.size() - 1):
		var previous: Vector2 = result[result.size() - 1]
		var current: Vector2 = path[index]
		var next: Vector2 = path[index + 1]
		var a := current - previous
		var b := next - current
		if absf(a.x * b.y - a.y * b.x) > 1.0 or a.dot(b) < 0.0:
			result.append(current)
	result.append(path[path.size() - 1])
	return result
