class_name Player
extends CharacterBody2D

@onready var hit_component: HitComponent = $HitComponent

@export var currentTool: DataTypes.Tools = DataTypes.Tools.None
var player_direction: Vector2

func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)
	
func on_tool_selected(tool: DataTypes.Tools)->void:
	currentTool = tool
	hit_component.current_tool = tool
	print("Tool:", tool)
