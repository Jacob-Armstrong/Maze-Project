extends TileMap

var start_coords = Vector2i(0, 0)

const LAYER = 0
const SOURCE = 0
const PATH_ATLAS_COORDS = Vector2i(0, 0)
const WALL_ATLAS_COORDS = Vector2i(1, 0)

@export var y_size = 30
@export var x_size = 30

var adjacent = [
	Vector2i(-1, 0), # Left
	Vector2i(1, 0), # Right
	Vector2i(0, 1), # Down
	Vector2i(0, -1) # Up
]

func _ready():
	y_size = Globals.grid_size_x
	x_size = Globals.grid_size_y
	
	create_global_border()
	generate_maze()

# Add wall tile to specified coordinates
func create_wall(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, WALL_ATLAS_COORDS)

# Add path tile to specified coordinates
func create_path(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, PATH_ATLAS_COORDS)

func is_wall(coords: Vector2): # Return true if tile is wall
	return get_cell_atlas_coords(LAYER, coords) == WALL_ATLAS_COORDS

func isWallCoord(coords: Vector2i):
	return (coords.x % 2 == 1 and coords.y % 2 == 1)

func isValidMove(coords: Vector2): # Move is in bounds and not a wall
	return (coords.x >= 0 and coords.y >= 0 and coords.x < x_size and coords.y < y_size and not is_wall(coords))

func generate_maze():
	var frontier: Array[Vector2i] = [start_coords]
	var explored = {}
	
	while frontier.size() > 0:
		var move = frontier.pop_back()
		explored[move] = true
		
		#if move in explored or not isValidMove(move):
			#await get_tree().create_timer(Globals.delay).timeout
		
		# Create walls in grid pattern while exploring
		if isWallCoord(move):
			create_wall(move)
		
		#await get_tree().create_timer(Globals.delay).timeout
		
		var valid_path = false
		adjacent.shuffle()
		for side in adjacent:
			var possible_move = move + side
			
			if possible_move not in explored and isValidMove(possible_move):
				if isWallCoord(possible_move):
					create_wall(possible_move)
				else:
					valid_path = true
					frontier.append(possible_move)
		
		if not valid_path:
			create_wall(move)
		else:
			create_path(move)

# Create border around maze
func create_global_border():
	for y in range(-1, y_size): # Left border
		create_wall(Vector2(-1, y))
	for y in range(-1, y_size + 1): # Right Border
		create_wall(Vector2i(x_size, y))
	for x in range(-1, x_size): # Top border
		create_wall(Vector2i(x, -1))
	for x in range(-1, x_size + 1): # Bottom Border
		create_wall(Vector2i(x, y_size))
