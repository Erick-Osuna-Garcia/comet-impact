extends Node3D

@onready var lbl = $CanvasLayer/HUD/Label
@onready var bt_menu = $CanvasLayer/HUD/Bt_Menu
@onready var bt_menu2 = $CanvasLayer/HUD/Bt_Menu2
@onready var layer = $CanvasLayer/HUD/layer
@onready var lb_layer = $CanvasLayer/HUD/Lb_Layer

var menu_abierto := false



func _process(delta):
	lbl.actualizar_texto("Energía: 100 | Impactos: 0")

func _on_bt_menu_pressed() -> void:
	_toggle_menu()

func _on_bt_menu_2_pressed() -> void:
	_toggle_menu()

func _toggle_menu() -> void:
	menu_abierto = not menu_abierto
	bt_menu.visible = not menu_abierto
	bt_menu2.visible = menu_abierto
	layer.visible = menu_abierto
	lb_layer.visible = menu_abierto
