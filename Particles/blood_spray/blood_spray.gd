extends GPUParticles3D

@onready var timer_handle : Timer = $Timer

func _ready():
	timer_handle.timeout.connect(_on_Timer)

func _on_Timer():
	self.queue_free()
