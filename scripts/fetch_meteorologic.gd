extends Node

onready var http_request = HTTPRequest.new()

func _ready():
    http_request.connect("request_completed", self, "_on_request_completed")
    http_request.request("https://api.meteorit.org/v1/meteorites")

func _on_request_completed(result, response_code, headers, body):
    print(body)