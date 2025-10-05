extends Control

@onready var lbl_energia = $Energia
@onready var lbl_impactos = $Impactos

# Función para actualizar los valores
func actualizar_datos():
	lbl_energia.text = "Energía: " 
	lbl_impactos.text = "Impactos: " 
