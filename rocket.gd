extends RigidBody3D

var up_force: float = 200.0
var torque_strength: float = 50
var stabilize_torque_strength: float = 50.0  # Strength of stabilizing torque
var stable_up_force: float = 200.0  # Upward force when stabilized
var is_stabilized: bool = false

# PID controller variables
var p_gain: float = 2.0
var i_gain: float = 0.1
var d_gain: float = 1.0
var integral: Vector3 = Vector3.ZERO
var last_error: Vector3 = Vector3.ZERO

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		is_stabilized = !is_stabilized  # Toggle stabilization mode
		integral = Vector3.ZERO  # Reset integral when mode changes
		$GPUParticles3D.emitting = true
	if is_stabilized:
		stabilize_and_move_up(delta)
	else:
		handle_manual_control()

func stabilize_and_move_up(delta: float):
	# Apply PID control for stabilization
	var current_up = global_transform.basis.y
	var desired_up = -Vector3.UP
	var error = desired_up.cross(current_up)
	
	integral += error * delta
	var derivative = (error - last_error) / delta
	last_error = error
	
	var pid_torque = error * p_gain + integral * i_gain + derivative * d_gain
	apply_torque(pid_torque * stabilize_torque_strength)
	
	# Apply upward force only in the direction of the cylinder's tip
	var tip_direction = global_transform.basis.y
	var force_magnitude = stable_up_force * max(0, tip_direction.dot(Vector3.UP))
	apply_central_force(tip_direction * force_magnitude)
	
	

func handle_manual_control():
	# Handle jumping
	if Input.is_action_pressed("ui_select"):
		var tip_direction = global_transform.basis.y
		apply_central_force(tip_direction * up_force)
		$GPUParticles3D.emitting = true
	
	if Input.is_action_just_released("ui_select"):
		$GPUParticles3D.emitting = false
	
	# Handle WASD movement
	var torque = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"):
		torque += Vector3(-1, 0, 0)
	if Input.is_action_pressed("ui_down"):
		torque += Vector3(1, 0, 0)
	if Input.is_action_pressed("ui_left"):
		torque += Vector3(0, 0, 1)
	if Input.is_action_pressed("ui_right"):
		torque += Vector3(0, 0, -1)
	
	# Apply the torque
	apply_torque(torque * torque_strength)
