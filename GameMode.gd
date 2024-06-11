extends Node3D

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta : float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)