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
onready var yellow_cube_spatial = $YellowCubeSpatial
#onready var yellow_cube_scene = load("res://scenes/YellowCube.tscn")
onready var basic_house_scene = load("res://scenes/BasicHouse3.tscn")
onready var basic_town_hall_scene = load("res://scenes/BasicTownHall.tscn")
onready var basic_tree_scene = load("res://scenes/BasicTree1.tscn")
onready var no_gold_label = $NoGoldErrMsgTextureRect/NoGoldErrMsgLabel
onready var city_tutorial_label = $CityTutorialMsgTextureRect2/CityTutorialMsgLabel

onready var townhallBuildableEntity = null
onready var houseBuildableEntity = null
onready var treeBuildableEntity = null

func _ready():
	randomize()
	_move_reward()
	no_gold_label.text = ""
	townhallBuildableEntity = BuildableEntity.new()
	townhallBuildableEntity.entity_ui_area = $TownHallUISpatial/TownHallUICube/Area
	townhallBuildableEntity.scene_instance = basic_town_hall_scene
	townhallBuildableEntity.gold_price = 125
	houseBuildableEntity = BuildableEntity.new()
	houseBuildableEntity.entity_ui_area = $HouseUISpatial/HouseUICube/Area
	houseBuildableEntity.scene_instance = basic_house_scene
	houseBuildableEntity.gold_price = 75
	#houseBuildableEntity.gold_price = 1
	treeBuildableEntity = BuildableEntity.new()
	treeBuildableEntity.entity_ui_area = $TreeUISpatial/TreeUICube/Area
	treeBuildableEntity.scene_instance = basic_tree_scene
	treeBuildableEntity.gold_price = 25
	city_tutorial_label.text = "Build a city with gold. Town hall: " + str(townhallBuildableEntity.gold_price) + "g, House: " + str(houseBuildableEntity.gold_price) + "g, Tree: " + str(treeBuildableEntity.gold_price)
	pass

class BuildableEntity:
	var entity_ui_area = null
	var entity_ui_area_hit = false
	var entity_must_be_built = false
	var last_entity_building_number = 0
	var entity_building_number = 0
	var entities = []
	var entity_building = null
	var scene_instance = null
	var gold_price = 0
	
	func do_lmb_logic(hit):
		if hit.size() != 0:
			if hit.collider_id == entity_ui_area.get_instance_id():
				entity_ui_area_hit = true
				entity_building_number += 1
				
	func process_beginning():
		entity_building = null
		if (last_entity_building_number > 0):
			entity_building = entities[-1]
			
	func process_middle(mouse_position, main_camera, ground_top, add_to_node):
		if entity_ui_area_hit:
			#var mouse_pos = get_viewport().get_mouse_position()
			# change this!
			var mouse_pos = mouse_position
			var ray_origin = main_camera.project_ray_origin(mouse_pos)
			var ray_direction = main_camera.project_ray_normal(mouse_pos)
			var from = ray_origin
			var to = ray_origin + ray_direction * 1000.0
			var space_state = ground_top.get_world().direct_space_state
			var hit = space_state.intersect_ray(from, to)
			if hit.size() != 0:
				if entity_building_number == (last_entity_building_number + 1):
					#entity_building = scene_instance
					entity_building = scene_instance.instance()
					add_to_node.add_child(entity_building)
					entities.append(entity_building)
					last_entity_building_number += 1
				entity_building.set_translation(Vector3(hit.position.x, 0, hit.position.z))
				entity_must_be_built = true
	
	func input_add_logic(gold_entity):
		if entity_must_be_built:
			if gold_entity.gold >= gold_price:
				entity_must_be_built = false
				entity_ui_area_hit = false
				gold_entity.gold -= gold_price
			else:
				err_msg_not_enough_gold(gold_price, gold_entity.no_gold_label)
				
	func err_msg_not_enough_gold(gold_price, label):
		#finish me
		label.text = "Not enough gold: (Cost: " + str(gold_price) + ")"
		pass
	
	func input_remove_logic():
		if entity_must_be_built:
			entity_must_be_built = false
			entity_ui_area_hit = false
			entity_building.queue_free()
			entity_building = null

func _do_lmb():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = main_camera.project_ray_origin(mouse_pos)
	var ray_direction = main_camera.project_ray_normal(mouse_pos)
	var from = ray_origin
	var to = ray_origin + ray_direction * 1000.0
	var space_state = ground_top.get_world().direct_space_state
	var hit = space_state.intersect_ray(from, to)
	townhallBuildableEntity.do_lmb_logic(hit)
	houseBuildableEntity.do_lmb_logic(hit)
	treeBuildableEntity.do_lmb_logic(hit)

func _process(delta):
	reward_delay -= 1
	townhallBuildableEntity.process_beginning()
	houseBuildableEntity.process_beginning()
	treeBuildableEntity.process_beginning()
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
	townhallBuildableEntity.process_middle(get_viewport().get_mouse_position(), main_camera, ground_top, self)
	houseBuildableEntity.process_middle(get_viewport().get_mouse_position(), main_camera, ground_top, self)
	treeBuildableEntity.process_middle(get_viewport().get_mouse_position(), main_camera, ground_top, self)
	if Input.is_action_just_pressed("Q"):
		# place the building
		townhallBuildableEntity.input_add_logic(self)
		houseBuildableEntity.input_add_logic(self)
		treeBuildableEntity.input_add_logic(self)
	if Input.is_action_just_pressed("E"):
		# cancel building placement
		townhallBuildableEntity.input_remove_logic()
		houseBuildableEntity.input_remove_logic()
		treeBuildableEntity.input_remove_logic()
	
func _move_reward():
	var x_range = rand_range(-21.7, 21.7)
	var z_range = rand_range(-4.0, 5.1)
	reward_spatial.set_translation(Vector3(x_range, reward_spatial.translation.y, z_range))
	pass