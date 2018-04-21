extends Node

onready var car_area = $CarSpatial/CarCube/Area
onready var car_spatial = $CarSpatial
onready var road_top_area = $RoadTopCube/Area
onready var gold_label = $GoldTextureRect/GoldLabel
onready var reward_spatial = $RewardSpatial
onready var reward_basic_cube_area = $RewardSpatial/RewardBasicCube/Area
onready var gold = 0.0
onready var speed = 20.0
onready var reward_delay_default = 15 #frames
onready var reward_delay = reward_delay_default
onready var main_camera = $MainCamera
onready var ground_top = $GroundTop
onready var town_hall_ui_spatial = $TownHallUISpatial
onready var th_ui_area = $TownHallUISpatial/TownHallUICube/Area
onready var th_ui_area_hit = false
onready var yellow_cube_spatial = $YellowCubeSpatial
onready var th_building = false
onready var yellow_cube_scene = load("res://scenes/YellowCube.tscn")
onready var last_building_number = 0
onready var building_number = 0
onready var town_halls = []

onready var house_ui_area = $HouseUISpatial/HouseUICube/Area
onready var house_ui_area_hit = false
onready var house_must_be_built = false
onready var last_house_building_number = 0
onready var house_building_number = 0
onready var houses = []

onready var houseBuildableEntity = null

class BuildableEntity:
	var entity_ui_area = null
	var entity_ui_area_hit = false
	var entity_must_be_built = false
	var last_entity_building_number = 0
	var entity_building_number = 0
	var entities = []
	
	func do_lmb_logic(hit):
		if hit.size() != 0:
			if hit.collider_id == entity_ui_area.get_instance_id():
				entity_ui_area_hit = true
				entity_building_number += 1

func _ready():
	randomize()
	_move_reward()
	houseBuildableEntity = BuildableEntity.new()
	houseBuildableEntity.entity_ui_area = $HouseUISpatial/HouseUICube/Area
	houseBuildableEntity.entity_ui_area_hit = false
	houseBuildableEntity.entity_must_be_built = false
	houseBuildableEntity.last_entity_building_number = 0
	houseBuildableEntity.entity_building_number = 0
	houseBuildableEntity.entities = []
	pass

func _do_lmb():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = main_camera.project_ray_origin(mouse_pos)
	var ray_direction = main_camera.project_ray_normal(mouse_pos)
	var from = ray_origin
	var to = ray_origin + ray_direction * 1000.0
	var space_state = ground_top.get_world().direct_space_state
	var hit = space_state.intersect_ray(from, to)
	if hit.size() != 0:
		if hit.collider_id == th_ui_area.get_instance_id():
			th_ui_area_hit = true
			building_number += 1
#		if hit.collider_id == house_ui_area.get_instance_id():
#			house_ui_area_hit = true
#			house_building_number += 1
	houseBuildableEntity.do_lmb_logic(hit)

func _process(delta):
	reward_delay -= 1
	var building = null
	if (last_building_number > 0):
		building = town_halls[town_halls.size() - 1]
	var house_building = null
	if (last_house_building_number > 0):
		house_building = houses[-1]
	if car_area.overlaps_area(road_top_area):
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
	if Input.is_action_just_pressed("LMB"):
		_do_lmb()
	if th_ui_area_hit:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = main_camera.project_ray_origin(mouse_pos)
		var ray_direction = main_camera.project_ray_normal(mouse_pos)
		var from = ray_origin
		var to = ray_origin + ray_direction * 1000.0
		var space_state = ground_top.get_world().direct_space_state
		var hit = space_state.intersect_ray(from, to)
		if hit.size() != 0:
			if building_number == (last_building_number + 1):
				building = yellow_cube_scene.instance()
				self.add_child(building)
				town_halls.append(building)
				last_building_number += 1
			building.set_translation(Vector3(hit.position.x, 0, hit.position.z))
			th_building = true
	pass
	if house_ui_area_hit:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = main_camera.project_ray_origin(mouse_pos)
		var ray_direction = main_camera.project_ray_normal(mouse_pos)
		var from = ray_origin
		var to = ray_origin + ray_direction * 1000.0
		var space_state = ground_top.get_world().direct_space_state
		var hit = space_state.intersect_ray(from, to)
		if hit.size() != 0:
			if house_building_number == (last_house_building_number + 1):
				house_building = yellow_cube_scene.instance()
				self.add_child(house_building)
				houses.append(house_building)
				last_house_building_number += 1
			house_building.set_translation(Vector3(hit.position.x, 0, hit.position.z))
			house_must_be_built = true
	pass
	if Input.is_action_just_pressed("Q"):
		# place the building
		if th_building:
			th_building = false
			th_ui_area_hit = false
		if house_must_be_built:
			house_must_be_built = false
			house_ui_area_hit = false
	if Input.is_action_just_pressed("E"):
		# cancel building placement
		if th_building:
			th_building = false
			th_ui_area_hit = false
			building.queue_free()
			building = null
		if house_must_be_built:
			house_must_be_built = false
			house_ui_area_hit = false
			house_building.queue_free()
			house_building = null
	
func _move_reward():
	var x_range = rand_range(-21.7, 21.7)
	var z_range = rand_range(-4.0, 5.1)
	reward_spatial.set_translation(Vector3(x_range, reward_spatial.translation.y, z_range))
	pass