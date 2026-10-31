class_name MonthNodeRunner
extends Node

## 按事件表播一个月的流程（B 方案）：只认五种屏。
##
##   剧情面板 main_story / 手册 handbook / 手机 phone_batch / 月末 month_close
##   —— main_story 一律先走到 location 才开，不看数据里的 walk 标记，也不给瞬移。
##
## 城镇侧提供五件事：播剧情、设黄线、解锁手册、投递手机、开月末卡。
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


## 下一屏（跳过不满足条件的）：收尾那句"按谁谁的安排，去哪儿"要用它。
func peek_next() -> Dictionary:
	var i := index
	while i < nodes.size():
		var n: Dictionary = nodes[i]
		i += 1
		if _passes(n):
			return n
	return {}


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
	# 主线由 runner_walk_to 在出发前翻日期；其余节点没有走位，
	# 也必须在打开手册/手机/活动/月末卡前完成同一套日期同步。
	if type != "main_story":
		town.call("runner_prepare_node_date", node, Callable(self, "_dispatch_prepared"))
		return
	_dispatch_prepared()


func _dispatch_prepared() -> void:
	var node: Dictionary = current
	var type := String(node.get("nodeType", "main_story"))
	if type == "handbook":
		town.call("runner_unlock_handbook", node)
		_next()
		return
	if type == "phone_batch":
		# 城镇说这批消息是前置（requireRead）时不往下走：等玩家看完收件箱再继续。
		if not bool(town.call("runner_deliver_phone", node)):
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
	# 剧情一律走到才开：首月 E01 是手写开场，不经过这里；其余不再看 walk 标记。
	waiting_walk = true
	town.call("runner_walk_to", node)


## 条件两种写法：when.flag 成立才播；when.notFlag 成立就跳过这一节点。
## 后者是给"未获提名的人不进答辩厅"这类整段分支用的——一屏一屏写 notFlag 太容易漏。
func _passes(node: Dictionary) -> bool:
	var when = node.get("when")
	if when is Dictionary:
		var flag := String((when as Dictionary).get("flag", ""))
		if not flag.is_empty():
			return bool(town.call("runner_has_flag", flag))
		var not_flag := String((when as Dictionary).get("notFlag", ""))
		if not not_flag.is_empty():
			return not bool(town.call("runner_has_flag", not_flag))
	return true
