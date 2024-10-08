extends Camera2D

var maze_parent

# Called when the node enters the scene tree for the first time.
func _ready():
	adjust_camera()

func adjust_camera():
	if not maze_parent: return

	var maze = maze_parent.get_node("TileMap")
	var tile_size = 64
	var maze_size = Vector2(maze.x_size + 40, maze.y_size + 40) * tile_size

	if Globals.comparing:
		maze_size *= 2

	# Calculate zoom based on maze size, constrained to 690x690
	self.zoom = Vector2(690, 690) / maze_size

	# Ensure that the camera doesn't move outside of the maze boundaries
	var center_cell = Vector2(maze.x_size, maze.y_size) / 2
	if Globals.comparing:
		center_cell.x *= 2
		center_cell.y *= 2

	self.global_position = maze.to_global(maze.map_to_local(center_cell))

	# Limit camera position to ensure it stays within bounds of 690x690
	var half_size = Vector2(690, 690) / 1.8 * self.zoom
	self.global_position.x = clamp(self.global_position.x, half_size.x, maze_size.x - half_size.x)
	self.global_position.y = clamp(self.global_position.y, half_size.y, maze_size.y - half_size.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	maze_parent = get_parent().currentMaze
	adjust_camera()
