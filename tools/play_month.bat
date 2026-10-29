@echo off
chcp 65001 >/dev/null
set /p M=跳到第几个月（1-12）: 
start "" "D:\Apps\Godot\Godot_v4.7.2-stable_win64.exe" --path "E:\03_Projects\bear\workplace_town" -- --v12m-month=%M%
