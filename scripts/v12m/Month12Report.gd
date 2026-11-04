class_name Month12Report
extends RefCounted

## 十二个月报告装配器：把这一年留下的记录，按算法册 §6.1 的五个部分和 §6.2 的七行摘要
## 拼成一份能给人看的报告。
##
## 三条硬规矩（都来自册子，不在这份代码里发明）：
##  1. 每句话只能引用已经落账的记录；没有记录就说"观察不足"，不推断没做过的事。
##  2. 屏幕上不出现分数、阈值、百分位——所以这里只输出句子，数字一律不进文案。
##  3. 文案本身在 data/story/v12m/report_templates.json，代码只做挑选和填空，
##     要改措辞改那份文件，不要在这儿拼字符串。

const TEMPLATES_PATH := "res://data/story/v12m/report_templates.json"
const RUBRICS_PATH := "res://data/story/v12m/rubrics.json"
## 开局入职自评的题库（IPIP 公版题项）：自评这一路要按它换算方向。
const SELFREPORT_PATH := "res://data/story/v12m/selfreport.json"
const DIMENSIONS := ["S", "O", "N", "D"]
## 一个维度要下结论，至少要被看到这么多次、且跨这么几类场合（rubrics.json 的 evidenceFloor）。
const DEFAULT_MIN_RECORDS := 2
const DEFAULT_MIN_CONTEXTS := 2
## 大五那一块的展示顺序（开放性 / 尽责性 / 外向性 / 宜人性 / 情绪稳定）。
## 算法册 §3.2 只标了前四维，情绪稳定没有标定依据——那一轴照实写"这一版没测"，不猜。
const TRAIT_ORDER := ["O", "C", "E", "A", "N"]
const DEFAULT_MIN_TRAIT_EVENTS := 3
const DEFAULT_MIN_TRAIT_CONTEXTS := 2
## 估计量的兜底值（正常都从 rubrics.json 的 bt.estimator 读，见开发册 4.21）：
## shrinkageN 是收缩常数 K = n/(n+k)，bands 是"有点朝 / 更常朝"两条线，minGroupN 是分组最少几条。
const DEFAULT_SHRINK_N := 5
const DEFAULT_MIN_GROUP_N := 3
const DEFAULT_BAND_WEAK := 0.15
const DEFAULT_BAND_STRONG := 0.45
## 自评与行为差过这条线，报告就点名说两个不一样（待校准，同其它系数）。
const DEFAULT_CONFLICT_AT := 0.35


var _templates: Dictionary = {}
var _town: Node
## rubrics.json 读一次留着：B_t 结算要按特质循环取系数。
var _rubric_cache: Dictionary = {}
## 自评题库缓存（融合每维都要查一次方向，别一遍遍读盘）。
var _self_items_cache: Array = []


func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATES_PATH))
	if parsed is Dictionary:
		_templates = parsed as Dictionary
	else:
		push_error("读不到 %s，报告只能出空壳" % TEMPLATES_PATH)


## 组装一份报告。返回 {headline, sections, gameSummary, expand, gaps}。
func build(town: Node) -> Dictionary:
	_town = town
	var records := _records()
	var evidence := _evidence_by_dimension(records)
	var sections: Array = []
	var personality := _personality((records.get("bt", []) as Array))
	sections.append(_summary_section(evidence))
	sections.append(_competency_section(evidence))
	sections.append(_behaviour_section(records, personality))
	sections.append(_activity_section(records))
	sections.append(_next_section(evidence))
	return {
		"headline": _headline(),
		"pageTitle": "截至第 7 月的报告" if int(_town.get("_month12_month")) == 7 and bool((_town.get("_month12_flags") as Dictionary).get("probation_ended", false)) else String(_templates.get("pageTitle", "这一年的报告")),
		"charts": _charts(evidence),
		"personality": personality,
		"requirements": _next_level_coverage(records, evidence),
		"direction": _direction(evidence),
		"tags": _tags(evidence),
		"captions": _templates.get("captions", {}),
		"sections": sections,
		"gameSummary": _game_summary(evidence),
		"expand": _expand(records, evidence),
		"gaps": _gaps(evidence),
	}


## 四维轮廓与覆盖条要的是"看得见的形状"，不是分数：
## 条的长度表示证据覆盖（被看到的次数 + 跨几类场合），旁边配一句人话。
## 册子 §6.5 不让出现阈值和隐藏总分，所以这里给的是 0–1 的覆盖比例和档位词，没有分数。
func _charts(evidence: Dictionary) -> Array:
	var rows: Array = []
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		var count := int(stat.get("count", 0))
		var contexts := int(stat.get("contexts", 0))
		var best := int(stat.get("best", 0))
		# 覆盖比例：锚点档占 6 成，场合数占 4 成（最多 3 类场合算满）。
		var coverage := clampf(float(best) / 4.0, 0.0, 1.0) * 0.6 + clampf(float(contexts) / 3.0, 0.0, 1.0) * 0.4
		var level := "waiting"
		if bool(stat.get("enough", false)) and best >= 3:
			level = "solid"
		elif count > 0:
			level = "early"
		var short_names: Dictionary = _template_section("charts").get("shortNames", {}) as Dictionary
		rows.append({
			"key": dim,
			"name": _dim_name(dim),
			# 雷达轴上只放短名：「署名与证据表达」七个字会压到图形上。
			"short": String(short_names.get(dim, _dim_name(dim))),
			"coverage": coverage,
			"level": level,
			"levelWord": _level_word(level),
			"count": count,
			"contexts": contexts,
			"note": _chart_note(dim, stat, level),
		})
	return rows


func _level_word(level: String) -> String:
	var wording: Dictionary = _template_section("charts")
	var words: Dictionary = wording.get("levels", {}) as Dictionary
	return String(words.get(level, ""))


func _chart_note(dim: String, stat: Dictionary, level: String) -> String:
	var wording: Dictionary = _template_section("charts")
	var notes: Dictionary = wording.get("notes", {}) as Dictionary
	if level == "waiting":
		return _fill(String(notes.get("waiting", "")), [_dim_name(dim)])
	return _fill(String(notes.get(level, "")), [
		_dim_name(dim), _count_word(int(stat.get("count", 0))), _context_word(int(stat.get("contexts", 0))),
	])


## 覆盖只记到"跨几个月"这一层（月份是真有的，场合类型还没标定），所以话这么说。
## 册子 §6.5：屏幕上的话只形容程度，不报具体数——所以次数和月份跨度到一定量就换成说法。
func _context_word(count: int) -> String:
	var words := ["没有跨月", "只在一个月", "跨两个月", "跨三个月", "跨四个月", "跨五个月"]
	if count < words.size():
		return words[count]
	if count >= 9:
		return "几乎贯穿这一年"
	return "跨了大半年"


## 风格标签：只从已经成立的档位里取，凑不出就不给标签（不硬凑三个）。
func _tags(evidence: Dictionary) -> Array:
	var wording: Dictionary = _template_section("charts")
	var map: Dictionary = wording.get("tags", {}) as Dictionary
	var out: Array = []
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		if bool(stat.get("enough", false)) and int(stat.get("best", 0)) >= 3:
			var tag := String(map.get(dim, ""))
			if not tag.is_empty() and not out.has(tag):
				out.append(tag)
	return out


## 甲：下一级要求覆盖图。要求清单来自 rubrics.json 的 m12.needAny（册子 §5 的规则表），
## 覆盖与否只看这一年的旗标，缺的就是缺，不猜。
func _next_level_coverage(records: Dictionary, evidence: Dictionary) -> Array:
	var m12: Dictionary = _rubrics().get("m12", {}) as Dictionary
	var need: Dictionary = m12.get("needAny", {}) as Dictionary
	var labels: Dictionary = _template_section("requirements").get("names", {}) as Dictionary
	var flags: Dictionary = records.get("flags", {}) as Dictionary
	var rows: Array = []
	for key in need.keys():
		var wanted := (need[key] as Array)
		var hit := ""
		for flag in wanted:
			if _flag(flags, String(flag)):
				hit = String(flag)
				break
		var veto_hit := false
		for veto in (m12.get("vetoFlags", []) as Array):
			if String(veto) == hit:
				veto_hit = true
		rows.append({
			"label": String(labels.get(key, key)),
			"covered": not hit.is_empty() and not veto_hit,
			"cite": _requirement_cite(flags, hit),
		})
	return rows


func _requirement_cite(flags: Dictionary, hit: String) -> String:
	if hit.is_empty():
		return ""
	# 旗标名带月份前缀（m12_xxx / m03_xxx），月份能对上就写月份，对不上就不编。
	if hit.length() > 2 and hit[1] >= "0" and hit[1] <= "9":
		var month := hit.substr(1, 2).to_int()
		if month >= 1 and month <= 12:
			return "第 %d 月留下的记录" % month
	return "这一条有记录"


## 丙：方向倾向。只说"这一年更常靠哪一种"，不给岗位名、不下性格结论。
func _direction(evidence: Dictionary) -> Dictionary:
	var wording: Dictionary = _template_section("direction")
	var best_dim := ""
	var best_score := -1.0
	var weakest_dim := ""
	var weakest_score := 99.0
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		var score := float(int(stat.get("best", 0))) + float(int(stat.get("contexts", 0))) * 0.4
		if bool(stat.get("enough", false)) and score > best_score:
			best_score = score
			best_dim = dim
		if int(stat.get("count", 0)) < weakest_score:
			weakest_score = float(int(stat.get("count", 0)))
			weakest_dim = dim
	var out := {"line": "", "observe": ""}
	if best_dim.is_empty():
		out["line"] = String(wording.get("none", ""))
	else:
		var lines: Dictionary = wording.get("lines", {}) as Dictionary
		out["line"] = _fill(String(lines.get(best_dim, "")), [_dim_name(best_dim)])
	if not weakest_dim.is_empty():
		var observe: Dictionary = wording.get("observe", {}) as Dictionary
		out["observe"] = _fill(String(observe.get(weakest_dim, "")), [_dim_name(weakest_dim)])
	return out


# ---------------------------------------------------------------- 记录

## 把城镇那几本账一次取出来，后面只读这份快照。
func _records() -> Dictionary:
	return {
		"evidence": _town.get("_evidence_log") if _town != null else [],
		"activity": _town.get("_year_activity_log") if _town != null else [],
		"flags": _town.get("_month12_flags") if _town != null else {},
		"bt": _town.get("_bt_log") if _town != null else [],
		"thisMonthLedger": _town.get("_month_ledger") if _town != null else [],
		"thisMonth": int(_town.get("_month12_month")) if _town != null else 0,
	}


func _flag(flags: Dictionary, key: String) -> bool:
	return bool(flags.get(key, false))


func _flag_text(flags: Dictionary, key: String) -> String:
	var value = flags.get(key, "")
	return String(value) if value is String else ""


# ---------------------------------------------------------------- 能力四维

## 每个维度：看到几次、跨几类场合、最高到哪一档、代表那一次、有没有相反的一次。
func _evidence_by_dimension(records: Dictionary) -> Dictionary:
	var floor := _evidence_floor()
	var min_records := int(floor.get("minRecordsPerDimension", DEFAULT_MIN_RECORDS))
	var out := {}
	for dim in DIMENSIONS:
		var hits: Array = []
		for value in (records.get("evidence", []) as Array):
			var item := Dictionary(value)
			if String(item.get("dimension", "")) == dim:
				hits.append(item)
		var months := {}
		var best := 0
		var best_hit: Dictionary = {}
		var worst_hit: Dictionary = {}
		for hit in hits:
			months[int(hit.get("month", 0))] = true
			var anchor := int(hit.get("anchor", 0))
			if anchor > best:
				best = anchor
				best_hit = Dictionary(hit)
			if worst_hit.is_empty() or anchor < int(worst_hit.get("anchor", 9)):
				worst_hit = Dictionary(hit)
		var contexts := months.size()
		out[dim] = {
			"count": hits.size(),
			"contexts": contexts,
			"best": best,
			"bestHit": best_hit,
			"worstHit": worst_hit,
			"enough": hits.size() >= min_records and contexts >= int(floor.get("minContextTypes", DEFAULT_MIN_CONTEXTS)),
		}
	return out


func _evidence_floor() -> Dictionary:
	var section := _rubrics().get("m6", {}) as Dictionary
	var floor = section.get("evidenceFloor", {})
	return floor as Dictionary if floor is Dictionary else {}


## 整份 rubrics.json：判定门槛、B_t 系数、置信档都只认这一份，代码里不补数（开发册 4.21）。
## 城镇那份缓存可能还没加载（直接从第 12 月跳进来时就是空的），所以自己读一次并留着。
func _rubrics() -> Dictionary:
	if not _rubric_cache.is_empty():
		return _rubric_cache
	var cached = _town.get("_rubrics") if _town != null else {}
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		_rubric_cache = cached as Dictionary
		return _rubric_cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUBRICS_PATH))
	if parsed is Dictionary:
		_rubric_cache = parsed as Dictionary
	else:
		push_error("读不到 %s，门槛与系数按最轻处理" % RUBRICS_PATH)
	return _rubric_cache


# ---------------------------------------------------------------- 五个部分

func _summary_section(evidence: Dictionary) -> Dictionary:
	var block := _template_section("summary")
	var lines: Array = []
	var flags: Dictionary = _records().get("flags", {}) as Dictionary
	var status := _flag_text(flags, "m06_probation_status")
	var probation: Dictionary = block.get("probation", {}) as Dictionary
	match status:
		"confirmed":
			if _any_insufficient(evidence):
				lines.append(_text(probation, "confirmed"))
				lines.append(_text(probation, "insufficient"))
			else:
				lines.append(_text(probation, "confirmed"))
		"not_confirmed":
			lines.append(_fill(_text(probation, "not_confirmed"), [_weak_reason(evidence)]))
		"terminated":
			var clause := _flag_text(flags, "m06_redline_clause")
			lines.append(_fill(_text(probation, "terminated"), [clause]))
		_:
			lines.append(_text(probation, "insufficient"))
	var promo: Dictionary = block.get("promotion", {}) as Dictionary
	var promotion := _flag_text(flags, "m12_promotion_status")
	match promotion:
		"promoted":
			lines.append(_text(promo, "nominated"))
		"not_promoted":
			lines.append(_text(promo, "nominated_not_promoted"))
		"not_nominated":
			lines.append(_text(promo, "not_nominated"))
		_:
			lines.append(_text(promo, "early" if bool(flags.get("probation_ended", false)) else "missing"))
	var reason := _flag_text(flags, "m12_promotion_reason")
	if not reason.is_empty():
		lines.append("评估记录里留下的原因：%s。" % reason)
	return {"id": "summary", "title": _title("summary"), "lines": lines}


func _competency_section(evidence: Dictionary) -> Dictionary:
	var block := _template_section("competency")
	var dims: Dictionary = block.get("dimensions", {}) as Dictionary
	var lines: Array = []
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		var wording: Dictionary = dims.get(dim, {}) as Dictionary
		var name := String(wording.get("name", dim))
		if not bool(stat.get("enough", false)):
			lines.append(_insufficient_line(block, name, stat))
			continue
		var band := "weak"
		if int(stat.get("best", 0)) >= 3:
			band = "strong"
		elif int(stat.get("best", 0)) >= 2:
			band = "mid"
		lines.append("%s：%s" % [name, _text(wording, band)])
		var hit: Dictionary = stat.get("bestHit", {}) as Dictionary
		if not hit.is_empty():
			lines.append(_sentence(_fill(_text(block, "representative"),
				[str(int(hit.get("month", 0))), _phrase_of(hit)])))
		var worst: Dictionary = stat.get("worstHit", {}) as Dictionary
		if not worst.is_empty() and int(worst.get("anchor", 9)) <= 1 and int(stat.get("best", 0)) >= 3:
			lines.append(_fill(_text(block, "counter_evidence"), ["第 %d 月" % int(worst.get("month", 0))]))
	return {"id": "competency", "title": _title("competency"), "lines": lines}


## 观察不足分两种：一次都没留下的，和留下了但还不够下结论的。两句都不猜。
func _insufficient_line(block: Dictionary, dim_name: String, stat: Dictionary) -> String:
	var count := int(stat.get("count", 0))
	if count == 0:
		return _fill(_text(block, "insufficient_none"), [dim_name])
	return _fill(_text(block, "insufficient"), [
		dim_name, _count_word(count), _context_word(int(stat.get("contexts", 0))),
	])


func _behaviour_section(records: Dictionary, personality: Dictionary) -> Dictionary:
	var block := _template_section("behaviour")
	var lines: Array = []
	# 大五那一维凑不够"3 个独立事件 + 2 类情境"就只写观察不足（算法册 §3.3）；
	# 凑够了就把方向和那条最响的事实念出来，仍然不当性格用。
	var spoken := 0
	for value in (personality.get("rows", []) as Array):
		var row := Dictionary(value)
		for line in (row.get("lines", []) as Array):
			lines.append(String(line))
		if String(row.get("level", "waiting")) != "waiting":
			spoken += 1
	if spoken == 0:
		lines.append(_text(block, "insufficient"))
	var flags: Dictionary = records.get("flags", {}) as Dictionary
	if _flag(flags, "e19_blame_network") or _flag(flags, "e19_admitted_error") or _flag(flags, "incident_reported"):
		lines.append(_fill(_text(block, "attribution"), ["7", "事故当天的记录"]))
	if _flag(flags, "e07_c_psy_driven") or _flag(flags, "m03_e12_own_module_index"):
		lines.append(_fill(_text(block, "drive"), ["3"]))
	return {"id": "behaviour", "title": _title("behaviour"), "lines": lines}


func _activity_section(records: Dictionary) -> Dictionary:
	var block := _template_section("activity")
	var lines: Array = []
	var picked: Array = []
	var months_with := []
	for value in (records.get("activity", []) as Array):
		var month_log := Dictionary(value)
		var month := int(month_log.get("month", 0))
		var entries := (month_log.get("entries", []) as Array)
		if entries.is_empty():
			continue
		months_with.append(month)
		for entry in entries:
			var item := Dictionary(entry)
			var what := String(item.get("what", ""))
			if not what.is_empty() and not picked.has(what):
				picked.append(what)
	# 这个月还在进行中，账没归档，补上它才不会漏掉最后一段。
	var live := (records.get("thisMonthLedger", []) as Array)
	if not live.is_empty():
		var live_month := int(records.get("thisMonth", 0))
		if live_month >= 1 and not months_with.has(live_month):
			months_with.append(live_month)
		for entry in live:
			var item := Dictionary(entry)
			var what := String(item.get("what", ""))
			if not what.is_empty() and not picked.has(what):
				picked.append(what)
	if picked.is_empty():
		lines.append(_text(block, "none"))
	else:
		lines.append(_fill(_text(block, "used"), ["、".join(picked)]))
		# 只有确实安排过的月份才谈"哪几个月没安排"；整年几乎都空的时候，列出来只是噪声。
		var idle: Array = []
		for month in range(1, 13):
			if not months_with.has(month):
				idle.append("第 %d 月" % month)
		if not idle.is_empty() and idle.size() <= 8:
			lines.append(_fill(_text(block, "rest"), ["、".join(idle)]))
	lines.append(_text(block, "no_score"))
	return {"id": "activity", "title": _title("activity"), "lines": lines}


func _next_section(evidence: Dictionary) -> Dictionary:
	var block := _template_section("next")
	var lines: Array = []
	var limits := int(_template_report().get("maxSuggestions", 2))
	for dim in DIMENSIONS:
		if lines.size() >= limits:
			break
		var stat: Dictionary = evidence[dim]
		var wording: Dictionary = (_template_section("competency").get("dimensions", {}) as Dictionary).get(dim, {}) as Dictionary
		var name := String(wording.get("name", dim))
		if not bool(stat.get("enough", false)):
			var count := int(stat.get("count", 0))
			if count == 0:
				lines.append(_fill(_text(block, "from_none"), [name]))
			else:
				lines.append(_fill(_text(block, "from_insufficient"), [
					name, _count_word(count), _context_word(int(stat.get("contexts", 0))),
				]))
			continue
		if int(stat.get("best", 0)) <= 1:
			lines.append(_fill(_text(block, "from_gap"), [name]))
	if lines.is_empty():
		lines.append(_fill(_text(block, "from_gap"), ["把下一级要求里还没被记录覆盖的那项做出来"]))
	lines.append(_text(block, "limit"))
	return {"id": "next", "title": _title("next"), "lines": lines}


# ---------------------------------------------------------------- 七行摘要与展开区

func _game_summary(evidence: Dictionary) -> Array:
	var flags: Dictionary = _records().get("flags", {}) as Dictionary
	var rows: Array = []
	var job := ""
	var town_ui = _town.get("_town_ui_v2") if _town != null else null
	if town_ui != null and town_ui.has_method("_profile_snapshot"):
		job = String((town_ui.call("_profile_snapshot") as Dictionary).get("role", ""))
	var probation := _flag_text(flags, "m06_probation_status")
	var probation_word := "第 6 月未评估"
	if probation == "confirmed":
		probation_word = "第 6 月转正通过"
	elif probation == "not_confirmed":
		probation_word = "第 6 月未通过"
	elif probation == "terminated":
		probation_word = "第 6 月因红线解除"
	var strong := 0
	for dim in DIMENSIONS:
		if int((evidence[dim] as Dictionary).get("best", 0)) >= 3:
			strong += 1
	var values := {
		"identity": "%s · %s" % [job, probation_word],
		"skill": _cite_dim(evidence, "S"),
		"output": _cite_dim(evidence, "O"),
		"network": _cite_dim(evidence, "N"),
		"state": _cite_state(flags),
		"role": _cite_dim(evidence, "D"),
		"traces": _cite_traces(flags, strong),
	}
	for row in (_templates.get("game_summary", []) as Array):
		var item := Dictionary(row)
		var id := String(item.get("id", ""))
		rows.append({"label": String(item.get("label", "")), "value": String(values.get(id, ""))})
	return rows


func _expand(records: Dictionary, evidence: Dictionary) -> Array:
	var rows: Array = []
	var chain: Array = []
	var competency := _template_section("competency")
	for value in (records.get("evidence", []) as Array):
		var item := Dictionary(value)
		chain.append(_fill(_text(competency, "chain_line"), [
			str(int(item.get("month", 0))), _dim_name(String(item.get("dimension", ""))),
			_phrase_of(item), _anchor_word(int(item.get("anchor", 0))),
		]))
	var trend: Array = []
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		var count := int(stat.get("count", 0))
		if count == 0:
			trend.append(_fill(_text(competency, "insufficient_none"), [_dim_name(dim)]))
			continue
		# 覆盖只到"跨几个月"这一层（场合类型还没标定），次数和跨度都只说程度、不报数。
		trend.append(_fill(_text(competency, "trend"), [
			_dim_name(dim), _count_word(count), _context_word(int(stat.get("contexts", 0))),
			_anchor_word(int(stat.get("best", 0))),
		]))
	var by_id := {"chain": chain, "trend": trend}
	for row in (_templates.get("expand", []) as Array):
		var item := Dictionary(row)
		var id := String(item.get("id", ""))
		var lines: Array = by_id.get(id, []) as Array
		if lines.is_empty():
			lines = [String(item.get("content", ""))]
		rows.append({"label": String(item.get("label", "")), "lines": lines})
	return rows


func _gaps(evidence: Dictionary) -> Array:
	var gaps: Array = []
	for dim in DIMENSIONS:
		var stat: Dictionary = evidence[dim]
		if not bool(stat.get("enough", false)):
			gaps.append("%s：观察不足" % _dim_name(dim))
	return gaps


# ---------------------------------------------------------------- 文案零件

func _headline() -> String:
	var flags: Dictionary = _records().get("flags", {}) as Dictionary
	var probation := _flag_text(flags, "m06_probation_status")
	var promotion := _flag_text(flags, "m12_promotion_status")
	if probation == "terminated":
		return "第 7 月：在岗经历因红线结束"
	if probation == "not_confirmed" and bool(flags.get("probation_ended", false)):
		return "第 7 月：在岗经历到此结束"
	if promotion == "promoted":
		return "这一年：转正通过，晋升也拿到了"
	if promotion == "not_promoted":
		return "这一年：转正通过，晋升差记录"
	if promotion == "not_nominated":
		return "这一年：站稳了，但还没进下一级名单"
	return "这一年：把做过的事留成了记录"


func _template_section(id: String) -> Dictionary:
	for value in (_templates.get("sections", []) as Array):
		var item := Dictionary(value)
		if String(item.get("id", "")) == id:
			return item
	return {}


func _template_report() -> Dictionary:
	var report = _templates.get("report", {})
	return report as Dictionary if report is Dictionary else {}


func _title(id: String) -> String:
	return String(_template_section(id).get("title", id))


func _text(block: Dictionary, key: String) -> String:
	return String(block.get(key, ""))


## 引玩家原话的那句，末尾不能再补一个句号：选项原文常常自己就带"。"或"”"，
## 直接拼会变成"……给他看。。"。
func _sentence(text: String) -> String:
	var out := text.strip_edges()
	if out.is_empty():
		return out
	var last := out.substr(out.length() - 1, 1)
	if last in ["。", "！", "？", "…", "”", "’", "」", "』"]:
		return out
	return out + "。"


## 模板里用中文尖括号占位（<reason> / <月份> / <数量> / <清单> / <维度> / <行为> / <说法>），
## 按句子里出现的顺序依次填值。填不上的占位一律留空并去掉，屏幕上不能出现 <xxx>。
func _fill(line: String, values: Array) -> String:
	var out := line
	var used := 0
	var guard := 0
	while out.contains("<") and out.contains(">") and guard < 12:
		guard += 1
		var from := out.find("<")
		var to := out.find(">", from)
		if from < 0 or to <= from:
			break
		var token := out.substr(from, to - from + 1)
		var replacement := ""
		if used < values.size():
			replacement = String(values[used])
			used += 1
		out = out.replace(token, replacement)
	return out


func _dim_name(dim: String) -> String:
	var wording: Dictionary = (_template_section("competency").get("dimensions", {}) as Dictionary).get(dim, {}) as Dictionary
	return String(wording.get("name", dim))


## 屏上只出现玩家看得懂的话：优先用当时那句选项原文，
## 内部行为码认得就翻成人话，认不出就说"做过的一次选择"——绝不把代码印给玩家。
func _phrase_of(hit: Dictionary) -> String:
	var said := String(hit.get("choiceText", "")).strip_edges()
	if not said.is_empty():
		return said
	return _behavior_phrase(String(hit.get("behavior", "")))


func _behavior_phrase(code: String) -> String:
	if code.is_empty():
		return "做过的一次选择"
	var words := {
		"d_claim_authorship_in_room": "在会上把那段是自己做的说清楚",
		"o_run_both_then_choose": "两条路都跑过一遍才选",
		"n_write_open_items": "把待定项、责任人、下次确认写下来",
		"d_mark_ai_assisted": "生成出来的东西标了来源",
		"d_reproduce_record": "留下别人能复现的记录",
	}
	return String(words.get(code, "做过的一次选择"))


func _anchor_word(anchor: int) -> String:
	if anchor >= 4:
		return "复杂情境也能闭环"
	if anchor >= 3:
		return "不同情境下独立做到"
	if anchor >= 2:
		return "部分达到但不稳"
	if anchor >= 1:
		return "需要人推"
	return "没留下记录"


func _count_word(count: int) -> String:
	var words := ["没有", "一次", "两次", "三次", "四次", "五次"]
	if count < words.size():
		return words[count]
	return "很多次"


func _any_insufficient(evidence: Dictionary) -> bool:
	for dim in DIMENSIONS:
		if not bool((evidence[dim] as Dictionary).get("enough", false)):
			return true
	return false


func _weak_reason(evidence: Dictionary) -> String:
	for dim in DIMENSIONS:
		if int((evidence[dim] as Dictionary).get("best", 0)) <= 1:
			return "%s这一项还没看到独立做到的一次" % _dim_name(dim)
	return "能举出的记录不够"


func _cite_dim(evidence: Dictionary, dim: String) -> String:
	var stat: Dictionary = evidence[dim]
	if not bool(stat.get("enough", false)):
		return "观察不足，先不下结论"
	var hit: Dictionary = stat.get("bestHit", {}) as Dictionary
	if hit.is_empty():
		return "有记录，但没找到能引用的一次"
	return "第 %d 月：%s" % [int(hit.get("month", 0)), _phrase_of(hit)]


func _cite_state(flags: Dictionary) -> String:
	var hard := ""
	if _flag(flags, "m06_hardship_disclosed"):
		hard = "你自己说过那几个月在硬扛"
	elif _flag(flags, "m06_hardship_not_discussed"):
		hard = "那几个月你没说，记录里也没写"
	else:
		hard = "没有需要说明的身体负担记录"
	return hard


func _cite_traces(flags: Dictionary, strong: int) -> String:
	# 一句话里不能既说"没找到"又说"加上"：先数有什么，再决定怎么说。
	var parts: Array = []
	if _flag(flags, "m06_has_notes"):
		parts.append("署名的纪要")
	if _flag(flags, "handbook_read"):
		parts.append("翻过的手册")
	if strong >= 3:
		parts.append("能复现的技术记录")
	if parts.is_empty():
		return "能拿出来的材料还少，缺的是署名纪要和可复现记录这一类"
	return "留下了：%s。" % "、".join(parts)


# ---------------------------------------------------------------- 大五行为倾向

## 结算 B_t（算法册 §3.1–3.3）。三条口径照册子抄：
##  1. 同一事件同一特质只留质量最高的一条——这就是 d_i（同源的不再计一次）。
##  2. 权重 w = q × r × d × s：q 看强弱档、s 看来源（必玩 1.0 / 自由活动 0.5）、r 用全局系数。
##  3. 独立事件 ≥3 且情境类型 ≥2 才给方向；方向阈值 θ 册子说没校准前不写死，
##     所以这里只看加权和的符号，不看它有多大。
func _personality(signals: Array) -> Dictionary:
	var wording := _template_section("personality")
	var cfg: Dictionary = _rubrics().get("bt", {}) as Dictionary
	var quality: Dictionary = cfg.get("qualityWeights", {}) as Dictionary
	var source: Dictionary = cfg.get("sourceWeights", {}) as Dictionary
	var coefs: Dictionary = cfg.get("coefficients", {}) as Dictionary
	var relevance := float(coefs.get("r", 1.0))
	var min_events := int(cfg.get("minIndependentEvents", DEFAULT_MIN_TRAIT_EVENTS))
	var min_kinds := int(cfg.get("minContextTypes", DEFAULT_MIN_TRAIT_CONTEXTS))
	var est: Dictionary = cfg.get("estimator", {}) as Dictionary
	var shrink_n := maxi(1, int(est.get("shrinkageN", DEFAULT_SHRINK_N)))
	var min_group_n := int(est.get("minGroupN", DEFAULT_MIN_GROUP_N))
	var bands: Dictionary = est.get("bands", {}) as Dictionary
	var band_weak := float(bands.get("weak", DEFAULT_BAND_WEAK))
	var band_strong := float(bands.get("strong", DEFAULT_BAND_STRONG))
	var groups_cfg: Dictionary = est.get("contextGroups", {}) as Dictionary
	var self_cfg: Dictionary = cfg.get("selfReport", {}) as Dictionary
	var conflict_at := float(self_cfg.get("conflictThreshold", DEFAULT_CONFLICT_AT))
	var self_lines: Dictionary = wording.get("selfLines", {}) as Dictionary
	var priors := _self_priors()
	var names: Dictionary = wording.get("names", {}) as Dictionary
	var levels: Dictionary = wording.get("levels", {}) as Dictionary
	var lines: Dictionary = wording.get("lines", {}) as Dictionary
	var untested: Dictionary = wording.get("untested", {}) as Dictionary
	var rows: Array = []
	for trait_key in TRAIT_ORDER:
		var trait_name := String(names.get(trait_key, trait_key))
		var skip := String(untested.get(trait_key, "")).strip_edges()
		if not skip.is_empty():
			# 情绪稳定这一维没有标定依据：照实说没测，不画点、也不给零。
			rows.append({
				"key": trait_key, "name": trait_name, "short": trait_name,
				"level": "untested", "levelWord": String(levels.get("untested", "")),
				"coverage": 0.0, "measured": false, "tone": "gray", "events": 0, "contextTypes": 0,
				"direction": 0, "lines": [skip], "note": skip,
			})
			continue
		var kept := _trait_evidence(signals, trait_key, quality, source, relevance)
		var events := kept.size()
		var kinds := _trait_context_kinds(kept)
		var raw := _trait_score(kept)
		# 收缩：K = n/(n+k)。三条弱证据不能和十五条一样长——先按证据量把估计量往零拉回来。
		var shrink := 0.0
		if events > 0:
			shrink = float(events) / float(events + shrink_n)
		var estimate := raw * shrink
		# 融合（旧引擎那条）：后验 = 自评 + K ×（行为 − 自评）。
		# 没答自评就退回收缩后的行为；答了但这一年这一维没行为，就用你自己说的那句（下面单独交代）。
		var prior: Dictionary = priors.get(trait_key, {}) as Dictionary
		var has_prior := not prior.is_empty()
		if has_prior:
			var said := float(prior.get("value", 0.0))
			estimate = said if events == 0 else said + shrink * (raw - said)
		var direction := 0
		if absf(estimate) >= band_weak:
			direction = 1 if estimate > 0.0 else -1
		var groups := _trait_groups(kept, groups_cfg, min_group_n)
		var level := "waiting"
		if events > 0:
			level = "solid" if (events >= min_events and kinds >= min_kinds) else "early"
		# 门槛过了、但"有人在场"和"一个人"两组反着走：这本身就是结论，别拧成一句话（§3.3 第 4 条）。
		if level == "solid" and String(groups.get("status", "")) == "situational":
			level = "situational"
		var kind_word := _context_kind_word(wording, kinds)
		var out_lines: Array = []
		match level:
			"situational":
				out_lines.append(_fill(String(lines.get("situational", "")), [
					trait_name, String(groups.get("watchedName", "")), String(groups.get("aloneName", "")),
				]))
			"solid":
				if direction == 0:
					out_lines.append(_fill(String(lines.get("balanced", "")), [trait_name, kind_word]))
				else:
					var key := "solid" if direction > 0 else "negative"
					out_lines.append(_fill(String(lines.get(key, "")),
						[trait_name, kind_word, _best_fact(kept, direction)]))
				var counter := _counter_line(lines, kept)
				if not counter.is_empty():
					out_lines.append(counter)
			"early":
				out_lines.append(_fill(String(lines.get("early", "")), [trait_name, kind_word]))
			_:
				out_lines.append(_fill(String(lines.get("waiting", "")), [trait_name]))
		# 自评与行为的关系：只有自评时挑明"这条不画"；两边差太大时点名，不抹平。
		if has_prior and events == 0:
			out_lines.append(_fill(String(self_lines.get("only_self", "")), [trait_name]))
		elif has_prior and events >= min_events and absf(raw - float(prior.get("value", 0.0))) >= conflict_at:
			var said := float(prior.get("value", 0.0))
			# 三种说法：反号、同向但你把自己说满了、同向且记录更明显。别用"朝这一头"糊过去，
			# 那会让"你说你很稳 + 记录也偏稳"读起来像吵架。
			var gap := "weaker"
			if raw * said <= 0.0 and absf(raw) >= band_weak:
				gap = "opposite"
			elif absf(raw) > absf(said):
				gap = "stronger"
			var gap_words: Dictionary = self_lines.get("gapWords", {}) as Dictionary
			out_lines.append(_fill(String(self_lines.get("conflict", "")), [
				String(prior.get("text", "")), String(prior.get("word", "")),
				String(gap_words.get(gap, "")),
			]))
		# 条的长短 = 收缩后的一致性 |estimate|：证据少自然短，两边抵消也短，不会四条齐平。
		var tone := "gray"
		var level_word := String(levels.get(level, ""))
		var coverage := 0.0
		var words: Dictionary = wording.get("polarityWords", {}) as Dictionary
		if level == "situational":
			tone = "gold"
			coverage = clampf(absf(estimate), 0.12, 1.0)
		elif level == "solid":
			coverage = clampf(absf(estimate), 0.12, 1.0)
			if direction == 0:
				level_word = String(levels.get("balanced", level_word))
			else:
				tone = "green" if direction > 0 else "gold"
				var band := "pos" if direction > 0 else "neg"
				if absf(estimate) < band_strong:
					band += "Weak"
				level_word = String(words.get(band, level_word))
		elif level == "early":
			# 有线索但没够门槛：给一小截灰条，跟"完全没攒够"区分开。
			coverage = 0.08
		rows.append({
			"key": trait_key, "name": trait_name, "short": trait_name,
			"coverage": coverage, "level": level, "levelWord": level_word, "tone": tone,
			"measured": true, "events": events, "contextTypes": kinds,
			"direction": direction, "score": raw, "estimate": estimate,
			"prior": float(prior.get("value", 0.0)) if has_prior else null,
			"consistency": String(groups.get("status", "")), "lines": out_lines,
			"note": String(out_lines[0]) if not out_lines.is_empty() else "",
		})
	var caption := String(wording.get("caption", ""))
	if not priors.is_empty():
		var note := String(self_lines.get("prior_note", "")).strip_edges()
		if not note.is_empty():
			caption += "\n" + note
	return {"rows": rows, "caption": caption, "hasPrior": not priors.is_empty()}


## 开局自评 → 每维一个 −1..1 的先验（五点量表换算，方向照题库里的 dir）。
## 没答的维度不进表：不许把"没答"当成"答了中间那档"。
func _self_priors() -> Dictionary:
	var out := {}
	if _town == null:
		return out
	var ratings = _town.get("_self_ratings")
	if not (ratings is Dictionary) or (ratings as Dictionary).is_empty():
		return out
	var scale := _self_report_field("scale")
	for value in _self_report_items():
		var item := Dictionary(value)
		var trait_key := String(item.get("trait", ""))
		var answered := int((ratings as Dictionary).get(trait_key, 0))
		if answered < 1 or answered > 5:
			continue
		# 量表词一起带上：报告要说"你在哪句话上选了什么"，不能只念题干，
		# 否则玩家选了"不太符合"，屏幕上看去却像他 affirm 了那句话。
		out[trait_key] = {
			"value": clampf((float(answered) - 3.0) / 2.0 * float(item.get("dir", 1)), -1.0, 1.0),
			"text": String(item.get("text", "")),
			"word": String(scale[answered - 1]) if answered - 1 < scale.size() else "",
		}
	return out


## 自评题库里的一个顶层字段（量表词之类）。
func _self_report_field(key: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SELFREPORT_PATH))
	if parsed is Dictionary:
		return (parsed as Dictionary).get(key, []) as Array
	return []


func _self_report_items() -> Array:
	if not _self_items_cache.is_empty():
		return _self_items_cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SELFREPORT_PATH))
	if parsed is Dictionary:
		_self_items_cache = (parsed as Dictionary).get("items", []) as Array
	else:
		push_error("读不到 %s，自评这一路只能空着" % SELFREPORT_PATH)
	return _self_items_cache


## 一个特质的证据：按事件收敛（同事件只留质量最高那条），顺手把这条的权重算好。
func _trait_evidence(signals: Array, trait_key: String, quality: Dictionary, source: Dictionary, relevance: float) -> Array:
	var best := {}
	for value in signals:
		var sig := Dictionary(value)
		if String(sig.get("trait", "")) != trait_key:
			continue
		var event_id := String(sig.get("eventId", ""))
		var q := float(quality.get(String(sig.get("strength", "M")), 0.6))
		var s := float(source.get(String(sig.get("source", "main")), 1.0))
		var record := {
			"q": q,
			"weight": q * relevance * s,
			"dir": int(sig.get("dir", 0)),
			"context": String(sig.get("context", "")),
			"fact": String(sig.get("fact", "")),
			"month": int(sig.get("month", 0)),
		}
		if not best.has(event_id) or q > float((best[event_id] as Dictionary).get("q", 0.0)):
			best[event_id] = record
	var out: Array = []
	for key in best.keys():
		out.append(best[key])
	return out


func _trait_context_kinds(kept: Array) -> int:
	var kinds := {}
	for value in kept:
		var record := Dictionary(value)
		var context := String(record.get("context", ""))
		if not context.is_empty():
			kinds[context] = true
	return kinds.size()


## 跨情境一致性：把六类场合分成"有人在场"和"一个人"两组（旧引擎 watched / alone 的口径），
## 两组各够 min_group_n 条才判；反号 = 分场合，同号 = 稳定。任一组不够就判不了，不硬说。
func _trait_groups(kept: Array, groups_cfg: Dictionary, min_group_n: int) -> Dictionary:
	var out := {"status": "", "watchedName": "", "aloneName": ""}
	if groups_cfg.is_empty():
		return out
	var context_to_group := {}
	for group_key in groups_cfg.keys():
		for context in (groups_cfg[group_key] as Array):
			context_to_group[String(context)] = String(group_key)
	var sums := {}
	var counts := {}
	for group_key in groups_cfg.keys():
		sums[String(group_key)] = 0.0
		counts[String(group_key)] = 0
	for value in kept:
		var record := Dictionary(value)
		var group := String(context_to_group.get(String(record.get("context", "")), ""))
		if group.is_empty() or not counts.has(group):
			continue
		sums[group] = float(sums[group]) + float(record.get("dir", 0)) * float(record.get("weight", 0.0))
		counts[group] = int(counts[group]) + 1
	if int(counts.get("watched", 0)) < min_group_n or int(counts.get("alone", 0)) < min_group_n:
		return out
	var watched := float(sums["watched"]) / float(counts["watched"])
	var alone := float(sums["alone"]) / float(counts["alone"])
	out["watchedName"] = _group_word(groups_cfg, "watched")
	out["aloneName"] = _group_word(groups_cfg, "alone")
	if (watched > 0.0 and alone < 0.0) or (watched < 0.0 and alone > 0.0):
		out["status"] = "situational"
	elif watched != 0.0 and alone != 0.0:
		out["status"] = "consistent"
	return out


## 分组在句子里怎么说：取该组前两类的场合名，够具体又不堆一长串。
func _group_word(groups_cfg: Dictionary, group: String) -> String:
	var list := (groups_cfg.get(group, []) as Array)
	var parts: Array = []
	for index in mini(2, list.size()):
		parts.append(String(list[index]))
	return "、".join(parts)


## B_t = Σ(w × x) / Σw，返回带符号的 −1..1：符号是朝哪一头，绝对值是有多一致。
## 册子没给方向阈值 θ，所以这里不设线，只把算出来的数交给门槛判。
func _trait_score(kept: Array) -> float:
	var weight_sum := 0.0
	var score := 0.0
	for value in kept:
		var record := Dictionary(value)
		var w := float(record.get("weight", 0.0))
		weight_sum += w
		score += w * float(record.get("dir", 0))
	if weight_sum <= 0.0:
		return 0.0
	return clampf(score / weight_sum, -1.0, 1.0)


## 举证的这一条：取该方向上权重最大的那次行为，报告要的是能指着看的事实。
func _best_fact(kept: Array, direction: int) -> String:
	var best_weight := -1.0
	var out := ""
	for value in kept:
		var record := Dictionary(value)
		if direction != 0 and int(record.get("dir", 0)) != direction:
			continue
		var w := float(record.get("weight", 0.0))
		if w > best_weight:
			best_weight = w
			out = String(record.get("fact", ""))
	return out


## 有正反两面时不取平均抹平（§3.3 第 4 条）：把两边各点名一次。
## 两边落在不同场合就说"场合 A 和场合 B 不一样"；落在同一场合就换那一句，
## 不然屏幕上会出现"当众那几次和当众那几次不一样"这种废话。
func _counter_line(lines: Dictionary, kept: Array) -> String:
	var pos := _strongest_context(kept, 1)
	var neg := _strongest_context(kept, -1)
	if pos.is_empty() or neg.is_empty():
		return ""
	if pos == neg:
		return _fill(String(lines.get("counter_same", "")), [pos])
	return _fill(String(lines.get("counter", "")), [pos, neg])


## 该方向上权重最大的那一次是在什么场合做的。
func _strongest_context(kept: Array, want_dir: int) -> String:
	var best_weight := -1.0
	var out := ""
	for value in kept:
		var record := Dictionary(value)
		if int(record.get("dir", 0)) != want_dir:
			continue
		var w := float(record.get("weight", 0.0))
		if w > best_weight:
			best_weight = w
			out = String(record.get("context", ""))
	return out


## 情境类型数怎么说：册子只规定"≥2 类"这道门槛，没规定话术，所以说法进模板。
func _context_kind_word(wording: Dictionary, kinds: int) -> String:
	var words: Dictionary = wording.get("contextKinds", {}) as Dictionary
	var key := str(maxi(kinds, 1))
	if words.has(key):
		return String(words[key])
	return String(words.get("5", "跨好几类场合"))
