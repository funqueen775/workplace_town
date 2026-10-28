class_name MonthNodeRunner
extends Node

## 按事件表播一个月的流程（B 方案）：只认五种屏。
##
##   剧情面板 main_story / 手册 handbook / 手机 phone_batch / 月末 month_close
##   —— 走到某地是 main_story 上的一个开关（walk），不是第六种屏。
##
## 城镇侧提供六件事：播剧情、设黄线、瞬移、解锁手册、投递手机、开月末卡。
## 这里不碰任何数值和旗标：选项一确认就交回城镇记账，回来只问"下一步"。

var town: Node
var month := 0
var nodes: Array = []
var index := 0
var active := false
var waiting_walk := false
var current: Dictionary = {}

var _finished_callback := Callable()


func start(month_number: int, month_nodes: Array, finished_callback := Callable()) -> void:
	month = month_number
	nodes = month_nodes
	index = 0
	active = true
	waiting_walk = false
	_finished_callback = finished_callback
	_next()


## 面板关掉（结果页点过）之后下一屏。城镇在 outcome 回调里叫它。
func on_panel_closed() -> void:
	if not active:
		return
	# 面板是在发完这个信号之后才收尾的：同一帧里开下一屏会被它自己关掉，
	# 所以延后一帧再开。
	call_deferred("_next")


## 走到黄线终点。城镇在到达判定里叫它。
func on_walk_arrived() -> void:
	if not active or not waiting_walk:
		return
	waiting_walk = false
	town.call("runner_present_story", current)


func stop() -> void:
	active = false
	waiting_walk = false
	current = {}


func _next() -> void:
	if not active:
		return
	while index < nodes.size():
		var node: Dictionary = nodes[index]
		index += 1
		if not _passes(node):
			continue
		_dispatch(node)
		return
	active = false
	if _finished_callback.is_valid():
		_finished_callback.call(month)


func _dispatch(node: Dictionary) -> void:
	current = node
	var type := String(node.get("nodeType", "main_story"))
	if type == "handbook":
		town.call("runner_unlock_handbook", node)
		_next()
		return
	if type == "phone_batch":
		town.call("runner_deliver_phone", node)
		_next()
		return
	if type == "month_close":
		town.call("runner_open_close", node)
		return
	if type == "activity":
		# 自由安排已经按月份参数化了（格数读节点里的 budget），交给城镇去跑；
		# 城镇跑完会回调 _next，这里不能自己往下走。
		town.call("runner_open_activity", node)
		return
	# main_story：要走的先铺黄线，走到再弹；不用走的直接弹（开场那一屏就是切场）。
	if bool(node.get("walk", false)):
		waiting_walk = true
		town.call("runner_walk_to", node)
		return
	town.call("runner_present_story", node)


## 条件只认一种写法：when.flag —— 旗标存在且为真才播。
func _passes(node: Dictionary) -> bool:
	var when = node.get("when")
	if when is Dictionary:
		var flag := String((when as Dictionary).get("flag", ""))
		if not flag.is_empty():
			return bool(town.call("runner_has_flag", flag))
	return true
