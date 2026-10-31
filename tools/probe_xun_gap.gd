extends Node
## 验跨旬卡两拍：带 gapText（"两周后"）与不带，各播一次。
## 只装转场层，不启动整座镇（不依赖本地后端）。
## 判据：两次都能播完、日期格都落到「中旬」；带 gap 那次明显更长。

func _ready() -> void:
	var wipe = load("res://scripts/v12m/TransitionWipe.gd").new()
	add_child(wipe)
	var cell := Label.new()
	add_child(cell)
	var plain := await _play(wipe, cell, "")
	var with_gap := await _play(wipe, cell, "两周后")
	print("[对照] 不带 gap=%.2f 秒 / 带 gap=%.2f 秒" % [plain, with_gap])
	var ok := cell.text == "中旬" and plain > 1.2 and with_gap > plain + 0.4
	print("XUN_GAP_PROBE=", "PASS" if ok else "FAIL")
	get_tree().quit()


func _play(wipe, cell: Label, gap_text: String) -> float:
	cell.text = "上旬"
	var started := Time.get_ticks_msec()
	wipe.call("play_xun", "上旬", "中旬", cell, "第 3 月 · 中旬 · 上午", -1, false, null, "", gap_text)
	await wipe.finished
	var spent := float(Time.get_ticks_msec() - started) / 1000.0
	print("[播完] gap=「%s」%.2f 秒 格面=%s" % [gap_text, spent, cell.text])
	return spent