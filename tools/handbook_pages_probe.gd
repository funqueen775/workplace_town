extends Node
## 手册减量后的版面体检（不需要渲染）：
##   八页、每页有正文、3.2 那一页画了删除线、后记只出现在最后一页。
## 用法：<godot> --headless --path <PROJ> res://tools/handbook_pages_probe.tscn
## 期望输出：HB_OK pages=8，退出码 0。

const EXPECTED := ["1.1", "1.2", "1.3", "2.3", "2.4", "3.1", "3.2", "3.3"]
const AFTERWORD := "手册到这里就结束了"
## 运行时（_open_month12_handbook）读的是这一份；不传数据的 open() 会掉回旧 48 个月那本。
const HANDBOOK := "res://data/story/employee_handbook_12m.json"

var _fail := 0


func _ready() -> void:
	await get_tree().process_frame
	var book := HandbookPanel.new()
	add_child(book)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HANDBOOK))
	if not (parsed is Dictionary):
		_bad("读不到 %s" % HANDBOOK)
		get_tree().quit(1)
		return
	book.open(parsed)
	await get_tree().process_frame
	await get_tree().process_frame

	var ids: Array = book.chapter_ids()
	print("[hb] pages=", ids)
	if ids != EXPECTED:
		_bad("页不对：期望 %s" % [EXPECTED])

	for page_id in ids:
		book.call("_select_chapter", String(page_id))
		await get_tree().process_frame
		await get_tree().process_frame
		var labels := _labels(book.get("_content"))
		if labels.is_empty():
			_bad("%s 一页没有任何文字" % page_id)
			continue
		var has_after := _has_text(labels, AFTERWORD)
		var wants_after := String(page_id) == String(EXPECTED[EXPECTED.size() - 1])
		if has_after != wants_after:
			_bad("%s 页的后记状态不对（有=%s，应为 %s）" % [page_id, has_after, wants_after])
		var strike := _find_named(book.get("_content"), "Strike")
		var want_strike := String(page_id) == "3.2"
		if want_strike and strike == null:
			_bad("3.2 是划掉的条款，但没有画出删除线")
		if not want_strike and strike != null:
			_bad("%s 不该有删除线" % page_id)
		if strike != null:
			print("[hb] 3.2 删除线宽=", (strike as Control).size.x, " 高=", (strike as Control).size.y)

	if _fail == 0:
		print("HB_OK pages=%d" % ids.size())
	get_tree().quit(1 if _fail > 0 else 0)


func _bad(msg: String) -> void:
	_fail += 1
	push_error("HB_FAIL " + msg)


func _labels(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		if child is Label:
			out.append(child)
		out.append_array(_labels(child))
	return out


func _has_text(labels: Array, needle: String) -> bool:
	for value in labels:
		if String((value as Label).text).contains(needle):
			return true
	return false


func _find_named(node: Node, wanted: String) -> Control:
	for child in node.get_children():
		if child is Control and String(child.name) == wanted:
			return child
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null