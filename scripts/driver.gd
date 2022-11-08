class_name Driver extends CharacterBody2D

# speed
var move_spd := 0.0
@export var move_inc := 8.0
@export var move_dec := 8.0
@export var move_break := 8.0
@export var move_rev := 8.0
@export var move_max := 16.0
@export var move_back_max := 6.0

# turn
var turn_spd := 0.0
@export var turn_inc := 0.25
@export var turn_dec := 0.40
@export var turn_opp := 0.50
@export var turn_max := 1.00
@export var turn_control_curve: Curve

@export var lookahead_curve: Curve

# input
var _input_accelerate := false
var _input_break := false
var _input_turn := 0.0

func _ready() -> void:
	$TrailFX.visible = true
	$AccelerateFX.visible = true

func _process(delta: float) -> void:
	_input_accelerate = Input.is_action_pressed('accelerate')
	_input_break = Input.is_action_pressed('break')
	_input_turn = Input.get_axis('turn_left', 'turn_right')
	
	$AccelerateFX.emitting = _input_accelerate

func _physics_process(delta: float) -> void:
	if _input_break:
		if move_spd > 0:
			move_spd = move_toward(move_spd, -move_back_max, move_break * delta)
		else:
			move_spd = move_toward(move_spd, -move_back_max, move_rev * delta)
	elif _input_accelerate:
		move_spd = move_toward(move_spd, move_max, move_inc * delta)
	else:
		move_spd = move_toward(move_spd, 0.0, move_dec * delta)
	
	var spd_ratio := move_spd / move_max
	
	if _input_turn != 0.0:
		var input_sign: float = sign(_input_turn)
		var move_sign: float = sign(turn_spd)
		
		if input_sign == move_sign:
			turn_spd = move_toward(turn_spd, turn_max * input_sign, turn_inc * delta)
		else:
			turn_spd = move_toward(turn_spd, turn_max * input_sign, turn_opp * delta)
	else:
		turn_spd = move_toward(turn_spd, 0.0, turn_dec * delta)
	
	# var forward := transform.basis_xform(Vector2.RIGHT) # longer
	var forward := Vector2.RIGHT.rotated(rotation) # shorter
	
	# rotate
	var turn_control:float = turn_control_curve.sample_baked(abs(spd_ratio)) * sign(spd_ratio)
	rotate(turn_to_rad(turn_spd * turn_control) * delta)
	
	# move
	velocity = forward * (move_spd * 16)
	var hit := move_and_slide()
	
	if hit:
		move_spd = move_spd * -0.5
	
	$Camera2D.position = position + forward * lookahead_curve.sample_baked(sign(spd_ratio)) * sign(spd_ratio)

func turn_to_rad(turn: float) -> float:
	return 2.0 * PI * turn

func sign2(x: float) -> float:
	return 1.0 if x >= 0.0 else -1.0
