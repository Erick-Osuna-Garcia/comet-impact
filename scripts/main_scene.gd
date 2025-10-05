extends Control



func _on_bt_incio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_bt_opciones_pressed() -> void:
	pass # Replace with function body.


func _on_bt_salir_pressed() -> void:
	get_tree().quit()
	
	



func _ready() -> void:
	$AnimatedSprite2D.play("default")  # o la animación que tengas
