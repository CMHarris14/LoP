@tool
extends Path3D

# Toggle for if the platform is on one continuous path or should move back and forth on its path
@export var closed_loop : bool:
    set(value):
        closed_loop = value
        _loop_toggle(value)

# Editor button to smooth the current path 
@export var smooth_curve : bool:
    set(value):
        _smooth_curve()

@export var speed : float = 1.0

@onready var path : PathFollow3D = $PathFollow3D
@onready var animation : AnimationPlayer = $AnimationPlayer

func _ready():
    if not closed_loop and not Engine.is_editor_hint():
        animation.play("move")
        animation.speed_scale = speed
        set_process(false)

func _process(delta):
    if not Engine.is_editor_hint():
        path.progress += speed * delta

func _loop_toggle(closed : bool) -> void:
    if Engine.is_editor_hint():
        var path_nodes : Curve3D = self.get_curve()
        if closed:
            if path_nodes.point_count > 2:
                var start_point : Vector3 = path_nodes.get_point_position(0)
                var start_out : Vector3 = path_nodes.get_point_out(0)
                path_nodes.add_point(start_point, -start_out, Vector3.ZERO)
        elif path_nodes.point_count != 0:
            path_nodes.remove_point(path_nodes.point_count - 1)

func _smooth_curve():
    if Engine.is_editor_hint():
        var path_nodes : Curve3D = self.get_curve()
        for i in range(path_nodes.point_count-1):
            smooth_curve_point(path_nodes, i)
        
func smooth_curve_point(in_curve: Curve3D, point_idx: int):
    # Check the point index is within the valid range
    if point_idx < 0 or point_idx >= in_curve.get_point_count():
        print("Invalid point index: " + (str)point_idx)
        return

    # Get the position of the target point
    var pos = in_curve.get_point_position(point_idx)
    var in_vec = in_curve.get_point_in(point_idx)
    var out_vec = in_curve.get_point_out(point_idx)

    # Get the previous and next positions
    var prev_pos = pos
    if point_idx > 0:
        prev_pos = in_curve.get_point_position(point_idx - 1)
    
    var next_pos = pos
    if point_idx < in_curve.get_point_count() - 1:
        next_pos = in_curve.get_point_position(point_idx + 1)

    # Calculate the tangents
    var prev_tangent = (pos - prev_pos).normalized()
    var next_tangent = (next_pos - pos).normalized()

    # Average the tangents
    var avg_tangent = (prev_tangent + next_tangent).normalized()

    # Scale the tangents to smooth
    var node_scale = 0.5  # Adjust smoothing. 0.5 seems to work best in most cases
    var distance = (prev_pos.distance_to(pos) + next_pos.distance_to(pos)) / 2 * node_scale

    # Calculate the new in and out vectors based on the average tangent
    in_vec = -avg_tangent * distance
    out_vec = avg_tangent * distance

    # Set the new in and out vectors
    in_curve.set_point_in(point_idx, in_vec)
    in_curve.set_point_out(point_idx, out_vec)