extends Camera2D

var maze_parent

# Called when the node enters the scene tree for the first time.
func _ready():
	adjust_camera()

func adjust_camera():
	
	if not maze_parent: return
	
	var maze = maze_parent.get_node("TileMap")
	var tile_size = 64
	var maze_size = Vector2(maze.x_size + 10, maze.y_size + 10) * tile_size
	self.zoom =  Vector2(self.get_viewport().size) / maze_size
	#self.zoom -= Vector2(0.2, 0.2)
	var center_cell = Vector2(maze.x_size, maze.y_size) / 2
	center_cell.y -= 0
	self.global_position = maze.to_global(maze.map_to_local(center_cell))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	maze_parent = get_parent().currentMaze
	
	adjust_camera()
