extends CharacterBody3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var blood_particles = preload("res://Particles/blood_spray/blood_spray.tscn")

# movement
var move_speed : float = 5.0
var friction : float = 20.0
var jump_power : float = 8
var jump_charge : float = 0.0
# dashing
var dash_cooldown : float = 2.0
var dash_timer : float = dash_cooldown
var dash_duration : float = 0.1
var current_dash : float = 0.0
const DASH_POWER : float = 10
var dashing : bool = false
# camera
var mouse_sensitivity : float = 0.002
var zoom_sensitivity : float = 1
const ZOOM_MIN : float = 1.5
const ZOOM_MAX : float = 7.0
var twist_input : float = 0.0
var pitch_input : float = 0.0
var camera_distance : float = 3

@onready var twist_pivot : Node3D = $TwistPivot
@onready var pitch_pivot : Node3D = $TwistPivot/PitchPivot
@onready var spring_arm : SpringArm3D = $TwistPivot/PitchPivot/Spring
@onready var step_detector : RayCast3D = $StepTracer
@onready var body := $Mesh
@onready var initial_height : float = body.scale.y
@onready var initial_position : Vector3 = body.position
@onready var world : Node3D = get_parent()



func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement input and friction
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (twist_pivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var cur_speed = velocity.length()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		body.rotation.y = lerp_angle(body.rotation.y, atan2(direction.x, direction.z), delta * 5)
	else:
		cur_speed = move_toward(cur_speed, 0, friction * delta)
		var moving_dir = Vector2(velocity.normalized().x, velocity.normalized().z)
		if cur_speed > 0:
			velocity.x = moving_dir.x * cur_speed
			velocity.z = moving_dir.y * cur_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

	step_detector.rotation.y += 30
	if step_detector.is_colliding() and direction.length() > 0:
		var collision_point : Vector3 = step_detector.get_collision_point()
		self.position.y = lerpf(self.position.y, 0.32 + collision_point.y, 1)

	# Dashing
	# cooldown timer
	if dash_timer < dash_cooldown:
		dash_timer += delta
	# stop the dash after it's duration
	if dashing:
		current_dash += delta
	if current_dash >= dash_duration:
		move_speed /= DASH_POWER
		current_dash = 0.0
		dashing = false

	if Input.is_action_just_pressed("dash"):
		if dash_timer >= dash_cooldown:
			move_speed *= DASH_POWER
			dash_timer = 0.0
			current_dash = 0.0
			dashing = true
			var blood_spray = blood_particles.instantiate()
			blood_spray.position = body.global_position
			world.add_child(blood_spray)

	# Camera zoom
	if Input.is_action_just_pressed("zoom_in") or Input.is_action_just_pressed("zoom_out"):
		var zoom : float = -zoom_sensitivity if Input.is_action_just_pressed("zoom_in") else zoom_sensitivity
		var zoom_target : float = clamp(spring_arm.spring_length + zoom, ZOOM_MIN, ZOOM_MAX)
		spring_arm.spring_length = lerpf(spring_arm.spring_length, zoom_target, 1)

		# Handle jump.
	
	# Jumping
	if Input.is_action_pressed("jump") and is_on_floor():
		jump_charge = clamp(jump_charge + delta, 0.0, 1.0)
		body.scale.y = clamp(body.scale.y - (0.2 * delta), 0.8, initial_height)
		body.position.y = clamp(body.position.y - (0.08 * delta), -0.08, initial_position.y)
	if Input.is_action_just_released("jump"):
		velocity.y = jump_power * jump_charge
		jump_charge = 0.0
		body.scale.y = initial_height
		body.position.y = initial_position.y


# Any input that isn't specifically mapped in the project settings end up here
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# The mouse event values need to be inverted to make the camera behave how most games do
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
		update_camera()


# Update camera based on values changed in _unhandled_input()
func update_camera():
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(10))
	twist_input = 0.0
	pitch_input = 0.0