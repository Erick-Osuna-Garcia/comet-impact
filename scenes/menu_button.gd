extends Control

func _ready() -> void:
a	var popup = $CanvasLayer/HUD/HBoxContainer/MenuButton.get_popup()
	popup.about_to_show.connect(_on_menu_about_to_show)

func _on_menu_about_to_show() -> void:
	var boton = $CanvasLayer/HUD/HBoxContainer/MenuButton
	var popup = boton.get_popup()
	
	# Esperar un frame para asegurar que el popup tenga tamaño correcto
	await get_tree().process_frame

	# Si el popup aún no tiene tamaño, usar un valor estimado
	var popup_height = popup.size.y if popup.size.y > 0 else 100

	# Mueve el menú justo encima del botón
	popup.global_position = boton.global_position - Vector2(0, popup_height)
