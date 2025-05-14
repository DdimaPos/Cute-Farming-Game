extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

@export var food_drop_height: int = 40
@export var reward_output_radius: int = 10

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var reward_marker: Marker2D = $RewardMarker
@onready var interactable_label_component: Control = $InteractableLabelComponent

@export var reward_scene_dict := {
	"corn": preload("res://scenes/objects/plants/corn_harvest.tscn"),
	"tomato": preload("res://scenes/objects/plants/tomato_harvest.tscn"),
	"log": preload("res://scenes/objects/trees/log.tscn"),
	"stone": preload("res://scenes/objects/rocks/stone.tscn"),
	"milk": preload("res://scenes/objects/milk.tscn"),
	"egg": preload("res://scenes/objects/egg.tscn")
}

var in_range: bool
var is_chest_open: bool
var is_chest_feeding: bool

func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	
	GameDialogueManager.exchange_items.connect(on_exchange_items)

func on_interactable_activated() -> void:
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	if is_chest_open and not is_chest_feeding:
		animated_sprite_2d.play("chest_close")
		is_chest_open = false
	
	interactable_label_component.hide()
	in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if in_range and event.is_action_pressed("show_dialogue"):
		interactable_label_component.hide()
		animated_sprite_2d.play("chest_open")
		is_chest_open = true

		var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
		get_tree().root.add_child(balloon)
		balloon.start(load("res://dialogue/conversations/magic_chest.dialogue"), "start_magic")

func on_exchange_items(give_item: String, give_amount: int, reward_item: String, reward_amount: int) -> void:
	if !in_range:
		return

	is_chest_feeding = true

	var inventory: Dictionary = InventoryManager.inventory
	if !inventory.has(give_item) or inventory[give_item] < give_amount:
		print("Not enough", give_item)
		is_chest_feeding = false
		return

	for index in give_amount:
		var harvest_instance = reward_scene_dict[give_item].instantiate() as Node2D
		harvest_instance.global_position = Vector2(global_position.x, global_position.y - food_drop_height)
		get_tree().root.add_child(harvest_instance)
		var target_position = global_position

		var time_delay = randf_range(0.5, 0.75)
		await get_tree().create_timer(time_delay).timeout

		var tween = get_tree().create_tween()
		tween.tween_property(harvest_instance, "position", target_position, 0.5)
		tween.tween_property(harvest_instance, "scale", Vector2(0.5, 0.5), 0.5)
		tween.tween_callback(harvest_instance.queue_free)

		InventoryManager.remove_collectable(give_item)

	if is_chest_open:
		await get_tree().create_timer(1.0).timeout
		if !in_range:
			animated_sprite_2d.play("chest_close")
			is_chest_open = false


	# Trigger reward drop visually
	on_item_received(reward_item, reward_amount)

	is_chest_feeding = false


func on_item_received(reward_item: String, amount: int) -> void:
	call_deferred("add_reward_scene", reward_item, amount)

func add_reward_scene(reward_item: String, amount: int) -> void:
	if !reward_scene_dict.has(reward_item):
		print("Unknown reward item:", reward_item)
		return

	var reward_scene_packed: PackedScene = reward_scene_dict[reward_item]

	for i in amount:
		var reward_scene: Node2D = reward_scene_packed.instantiate()
		var reward_pos: Vector2 = get_random_position_in_circle(reward_marker.global_position, reward_output_radius)
		reward_scene.global_position = reward_pos
		get_tree().root.add_child(reward_scene)

func get_random_position_in_circle(center: Vector2, radius: int) -> Vector2i:
	var angle = randf() * TAU
	var distance = sqrt(randf()) * radius
	return Vector2i(center.x + distance * cos(angle), center.y + distance * sin(angle))
