extends Node

onready var car_area = $CarSpatial/CarCube/Area
#onready var car_cube = $CarSpatial/CarCube
onready var car_spatial = $CarSpatial
onready var road_top_area = $RoadTopCube/Area
onready var gold_label = $GoldTextureRect/GoldLabel
onready var reward_spatial = $RewardSpatial
onready var reward_basic_cube_area = $RewardSpatial/RewardBasicCube/Area
onready var gold = 0.0
onready var speed = 20.0
onready var reward_delay_default = 15 #frames
onready var reward_delay = reward_delay_default

func _ready():
	randomize()
	_move_reward()
	pass

func _process(delta):
	reward_delay -= 1
	if car_area.overlaps_area(road_top_area):
		#prints("over")
		gold += 0.1
		pass
	if car_area.overlaps_area(reward_basic_cube_area):
		if reward_delay < 1:
			_move_reward()
			gold += 15
			reward_delay = reward_delay_default
		pass
	gold_label.text = "Gold: " + str(gold)
	if Input.is_action_pressed("D"):
		car_spatial.translate(Vector3(speed * delta, 0, 0))
	if Input.is_action_pressed("A"):
		car_spatial.translate(Vector3(-speed * delta, 0, 0))
	if Input.is_action_pressed("S"):
		car_spatial.translate(Vector3(0, 0, speed * delta))
	if Input.is_action_pressed("W"):
		car_spatial.translate(Vector3(0, 0, -speed * delta))
	pass
	
func _move_reward():
	var x_range = rand_range(-21.7, 21.7)
	var z_range = rand_range(-4.0, 5.1)
	reward_spatial.set_translation(Vector3(x_range, reward_spatial.translation.y, z_range))
	pass