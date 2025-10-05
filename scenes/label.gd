extends Label

func _ready():
	text = "¡Hola HUD!"  # Texto inicial

func actualizar_texto(nuevo_texto: String):
	text = nuevo_texto
