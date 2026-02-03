extends TextureRect

func _ready():
	center_crosshair()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		center_crosshair()

func center_crosshair():
	var screen_size = get_viewport_rect().size
	position = (screen_size * 0.5) - (size * 0.5)
