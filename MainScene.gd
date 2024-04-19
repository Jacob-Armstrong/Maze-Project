extends Node2D

const maze = preload("res://Maze.tscn")
@onready var mazeButton = $CanvasLayer/UI/GenerateMazeButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_generate_maze_button_pressed():
	mazeButton.disabled = true
	var newMaze = maze.instantiate()
	var mazeNodes = $Maze.get_children()
	for child in mazeNodes:
		if child is TileMap:
			child.queue_free()
	add_child(newMaze)
	mazeButton.disabled = false
