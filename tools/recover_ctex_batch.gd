extends SceneTree
## 旧包 .ctex 批量转 PNG：读 test_artifacts/recover_tmp/map.json，
## 每项 {ctex, target}。用完即删，别留进仓库。

func _initialize() -> void:
	var map_path := "res://test_artifacts/recover_tmp/map.json"
	var text := FileAccess.get_file_as_string(map_path)
	var mapping = JSON.parse_string(text)
	if not (mapping is Array):
		print("MAP_FAIL")
		quit(1)
		return
	var ok := 0
	var fail := 0
	for item in mapping:
		var entry := Dictionary(item)
		var ctex := String(entry.get("ctex", ""))
		var target := String(entry.get("target", ""))
		var tex := load(ctex) as Texture2D
		if tex == null:
			print("LOAD_FAIL ", ctex)
			fail += 1
			continue
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var err := tex.get_image().save_png(target)
		if err != OK:
			print("SAVE_FAIL ", target, " err=", err)
			fail += 1
		else:
			print("SAVED ", target, " ", tex.get_size())
			ok += 1
	print("DONE ok=", ok, " fail=", fail)
	quit(0 if fail == 0 else 1)