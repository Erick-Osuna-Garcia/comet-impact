extends Node

@onready var http_request = HTTPRequest.new()

func _ready():
    http_request.request("https://api.meteorit.org/v1/meteorites")