# -*- coding: utf-8 -*-
"""照剧情册把第 4–6 月补齐：漏掉的回响拍、分支旁白、答辩四拍、月末考评提醒。
   文本一律取册子原文（含表格里的逐句），不自己编。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
EV = ROOT + r'\data\story\v12m\events.json'
MF = ROOT + r'\data\story\v12m\manifest.json'
GD = ROOT + r'\scripts\WorkplaceTown.gd'

raw = open(EV, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
doc = json.loads(raw.replace('\r\n', '\n'))
nodes = doc['nodes']
by_id = {str(n.get('id')): n for n in nodes}


def say(who, text):
    return {'type': 'say', 'speaker': who, 'text': text}


def nar(text, when=None):
    b = {'type': 'narration', 'text': text}
    if when:
        b['when'] = when
    return b


def insert(node, index, *beats):
    bs = node['beats']
    bs[index:index] = list(beats)


# ---------------------------------------------------------------- 引擎：拍上的条件支持 anyOf / noneOf
g = open(GD, encoding='utf-8', newline='').read().replace('\r\n', '\n')
old = '''			var not_flag := String(w.get("notFlag", ""))
			if not not_flag.is_empty() and bool(_month12_flags.get(not_flag, false)):
				continue'''
new = '''			var not_flag := String(w.get("notFlag", ""))
			if not not_flag.is_empty() and bool(_month12_flags.get(not_flag, false)):
				continue
			# 多条里命中一条才留（anyOf）/ 一条都没命中才留（noneOf）。
			# 答辩那一问要看"带进去的三张里有没有受挫那张"——那是四个旗标里的任意一个。
			any_of: Array = w.get("anyOf", []) as Array
			if not any_of.is_empty():
				var hit := false
				for value in any_of:
					if bool(_month12_flags.get(String(value), false)):
						hit = true
						break
				if not hit:
					continue
			none_of: Array = w.get("noneOf", []) as Array
			for value in none_of:
				if bool(_month12_flags.get(String(value), false)):
					continue
			if not none_of.is_empty() and _any_flag(none_of):
				continue'''
assert old in g, 'engine anchor'
g = g.replace(old, new, 1)
g = g.replace('''func runner_walk_to(node: Dictionary) -> void:''',
  '''## 一组旗标里有没有任意一条成立。
func _any_flag(flags: Array) -> bool:
	for value in flags:
		if bool(_month12_flags.get(String(value), false)):
			return true
	return false


func runner_walk_to(node: Dictionary) -> void:''', 1)
open(GD, 'w', encoding='utf-8', newline='').write(g.replace('\n', '\r\n' if '\r\n' in open(GD, encoding='utf-8', newline='').read() else '\n'))
print('引擎：拍条件支持 anyOf / noneOf')
