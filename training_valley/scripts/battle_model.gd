class_name BattleModel
extends RefCounted

const PLAYER_MAX_HP := 10
const WANG_MAX_HP := 10
const SONG_MAX_HP := 18
const HEAL_AMOUNT := 5
const COUNTER_DAMAGE := 2

var rng := RandomNumberGenerator.new()

var player_hp := PLAYER_MAX_HP
var wang_hp := WANG_MAX_HP
var song_hp := SONG_MAX_HP
var round_index := 0

var wang_rolls: Array[int] = []
var wang_choice_index := -1
var wang_attack_value := 0
var player_rolls: Array[int] = []
var player_pool: Array[Dictionary] = []
var hidden_pool_index := -1
var selected_pool_index := -1
var selected_was_hidden := false
var first_choice_recorded := false
var known_choice_count := 0
var unknown_choice_count := 0

var wang_skill_available := true
var wang_skill_triggered_this_round := false
var double_armed := false
var cards := {
	"double": 1,
	"heal": 1,
	"reroll": 1,
}


func reset(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	player_hp = PLAYER_MAX_HP
	wang_hp = WANG_MAX_HP
	song_hp = SONG_MAX_HP
	round_index = 0
	wang_rolls.clear()
	player_rolls.clear()
	player_pool.clear()
	wang_choice_index = -1
	wang_attack_value = 0
	hidden_pool_index = -1
	selected_pool_index = -1
	selected_was_hidden = false
	first_choice_recorded = false
	known_choice_count = 0
	unknown_choice_count = 0
	wang_skill_available = true
	wang_skill_triggered_this_round = false
	double_armed = false
	cards = {"double": 1, "heal": 1, "reroll": 1}


func begin_round() -> Dictionary:
	round_index += 1
	double_armed = false
	selected_pool_index = -1
	selected_was_hidden = false
	first_choice_recorded = false
	wang_skill_triggered_this_round = false

	wang_rolls = _roll_many(3)
	wang_choice_index = _index_of_max(wang_rolls)
	wang_attack_value = wang_rolls[wang_choice_index]
	player_rolls = _roll_many(3)

	player_pool.clear()
	for value in player_rolls:
		player_pool.append({"value": value, "source": "player", "hidden": false})
	for i in range(wang_rolls.size()):
		if i != wang_choice_index:
			player_pool.append({"value": wang_rolls[i], "source": "wang", "hidden": false})

	hidden_pool_index = rng.randi_range(0, player_pool.size() - 1)
	player_pool[hidden_pool_index]["hidden"] = true

	if wang_skill_available and _all_pool_values_at_most(4):
		var target_index := _best_visible_pool_index()
		if target_index >= 0:
			player_pool[target_index]["value"] = 6
			wang_skill_available = false
			wang_skill_triggered_this_round = true

	return get_round_snapshot()


func get_round_snapshot() -> Dictionary:
	return {
		"round": round_index,
		"wang_rolls": wang_rolls.duplicate(),
		"wang_choice_index": wang_choice_index,
		"wang_attack": wang_attack_value,
		"player_rolls": player_rolls.duplicate(),
		"pool": player_pool.duplicate(true),
		"hidden_index": hidden_pool_index,
		"known_choices": known_choice_count,
		"unknown_choices": unknown_choice_count,
		"wang_skill_triggered": wang_skill_triggered_this_round,
	}


func select_player_die(index: int) -> bool:
	if index < 0 or index >= player_pool.size():
		return false
	selected_was_hidden = bool(player_pool[index]["hidden"])
	if not first_choice_recorded:
		if selected_was_hidden:
			unknown_choice_count += 1
		else:
			known_choice_count += 1
		first_choice_recorded = true
	if selected_was_hidden:
		player_pool[index]["hidden"] = false
	selected_pool_index = index
	return true


func can_use_card(card_id: String) -> bool:
	return int(cards.get(card_id, 0)) > 0


func use_double() -> bool:
	if not can_use_card("double") or selected_pool_index < 0:
		return false
	cards["double"] = 0
	double_armed = true
	return true


func use_reroll() -> Dictionary:
	if not can_use_card("reroll") or selected_pool_index < 0:
		return {"used": false}
	if bool(player_pool[selected_pool_index]["hidden"]):
		return {"used": false}
	var old_value := int(player_pool[selected_pool_index]["value"])
	var new_value := _roll_die()
	player_pool[selected_pool_index]["value"] = new_value
	cards["reroll"] = 0
	return {"used": true, "old": old_value, "new": new_value}


func use_heal(target: String) -> Dictionary:
	if not can_use_card("heal"):
		return {"used": false}
	if target == "player":
		if player_hp >= PLAYER_MAX_HP:
			return {"used": false}
		var before := player_hp
		player_hp = min(PLAYER_MAX_HP, player_hp + HEAL_AMOUNT)
		cards["heal"] = 0
		return {"used": true, "target": target, "amount": player_hp - before}
	if target == "wang":
		if wang_hp >= WANG_MAX_HP:
			return {"used": false}
		var before := wang_hp
		wang_hp = min(WANG_MAX_HP, wang_hp + HEAL_AMOUNT)
		cards["heal"] = 0
		return {"used": true, "target": target, "amount": wang_hp - before}
	return {"used": false}


func resolve_wang_attack() -> Dictionary:
	var defense := _roll_die()
	return _resolve_ally_attack("wang", wang_attack_value, defense)


func resolve_player_attack() -> Dictionary:
	if selected_pool_index < 0:
		return {"resolved": false}
	var base_attack := int(player_pool[selected_pool_index]["value"])
	var multiplier := 2 if double_armed else 1
	var attack := base_attack * multiplier
	var defense := _roll_die()
	var result := _resolve_ally_attack("player", attack, defense)
	result["base_attack"] = base_attack
	result["multiplier"] = multiplier
	double_armed = false
	return result


func _resolve_ally_attack(attacker: String, attack: int, defense: int) -> Dictionary:
	var blocked := attack <= defense
	var damage := maxi(0, attack - defense)
	var counter := 0
	if blocked:
		counter = COUNTER_DAMAGE
		if attacker == "wang":
			wang_hp = maxi(0, wang_hp - counter)
		else:
			player_hp = maxi(0, player_hp - counter)
	else:
		song_hp = maxi(0, song_hp - damage)
	return {
		"resolved": true,
		"attacker": attacker,
		"attack": attack,
		"defense": defense,
		"blocked": blocked,
		"damage": damage,
		"counter": counter,
	}


func resolve_song_attack() -> Dictionary:
	var rolls := _roll_many(3)
	var choice_index := _index_of_max(rolls)
	var attack := rolls[choice_index]
	var defense := _roll_die()
	var target := "player" if rng.randi_range(0, 1) == 0 else "wang"
	var damage := maxi(0, attack - defense)
	if target == "player":
		player_hp = maxi(0, player_hp - damage)
	else:
		wang_hp = maxi(0, wang_hp - damage)
	return {
		"target": target,
		"rolls": rolls,
		"choice_index": choice_index,
		"attack": attack,
		"defense": defense,
		"damage": damage,
	}


func battle_result() -> String:
	if song_hp <= 0:
		return "victory"
	if player_hp <= 0 or wang_hp <= 0:
		return "defeat"
	return "ongoing"


func _roll_die() -> int:
	return rng.randi_range(1, 6)


func _roll_many(count: int) -> Array[int]:
	var values: Array[int] = []
	for _i in range(count):
		values.append(_roll_die())
	return values


func _index_of_max(values: Array[int]) -> int:
	var best_index := 0
	for i in range(1, values.size()):
		if values[i] > values[best_index]:
			best_index = i
	return best_index


func _all_pool_values_at_most(limit_value: int) -> bool:
	for die in player_pool:
		if int(die["value"]) > limit_value:
			return false
	return true


func _best_visible_pool_index() -> int:
	var best_index := -1
	for i in range(player_pool.size()):
		if bool(player_pool[i]["hidden"]):
			continue
		if best_index < 0 or int(player_pool[i]["value"]) > int(player_pool[best_index]["value"]):
			best_index = i
	return best_index
