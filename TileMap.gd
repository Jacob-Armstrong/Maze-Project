extends TileMap

# +--------------------+
# | Constant Variables |
# +--------------------+
const LAYER = 0
const SOURCE = 0
const PATH_ATLAS_COORDS = Vector2i(0, 0)
const WALL_ATLAS_COORDS = Vector2i(1, 0)
const SOLVED_ATLAS_COORDS = Vector2i(2, 0)

@export var x_size = 30
@export var y_size = 30
var start_coords = Vector2i(0, 0)

var path = []
var pathFound = false

var isSecondMaze
var solving
var timer = 0

# Array of cardinal directions
var adjacent = [
	Vector2i(-1, 0), # Left
	Vector2i(1, 0), # Right
	Vector2i(0, 1), # Down
	Vector2i(0, -1) # Up
]

func _ready():
	y_size = Globals.grid_size_x
	x_size = Globals.grid_size_y
	
	if not isSecondMaze:
		create_global_border()
		generate_maze()
	else:
		print("secondMaze spawned. path: " + str(path))
		resetMaze()

func _process(delta):
	if solving:
		timer += delta

# +---------------------------+
# | Maze Generation Functions |
# +---------------------------+

# Add wall tile to specified coordinates
func create_wall(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, WALL_ATLAS_COORDS)

# Add path tile to specified coordinates
func create_path(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, PATH_ATLAS_COORDS)

# Add red "solved" tile to specified coordinates
func place_solved_path(coords):
	set_cell(LAYER, coords, SOURCE, SOLVED_ATLAS_COORDS)

# Return true if tile is wall
func is_wall(coords: Vector2): 
	return get_cell_atlas_coords(LAYER, coords) == WALL_ATLAS_COORDS

# Return true if tile is even
func isWallCoord(coords: Vector2i):
	return (coords.x % 2 == 1 and coords.y % 2 == 1)

# Move is in bounds and not a wall
func isValidMove(coords: Vector2): 
	return (coords.x >= 0 and coords.y >= 0 and coords.x < x_size and coords.y < y_size and not is_wall(coords))

# Reset maze if already solved
func resetMaze():
	for coord in path:
		create_path(coord)
	path = []

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

# +----------------+
# | Maze Generator |
# +----------------+

func generate_maze():
	var frontier: Array[Vector2i] = [start_coords]
	var explored = {}
	
	while frontier.size() > 0:
		var move = frontier.pop_back()
		explored[move] = true
		
		if move in explored or not isValidMove(move):
			if Globals.isDelay:
				await get_tree().create_timer(Globals.delay).timeout
		
		# Create walls in grid pattern while exploring
		if isWallCoord(move):
			create_wall(move)
		
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
	
	# Generation done. Reenable buttons.
	Globals.enableSolveButtons.emit()

# +------------------------------+
# | Astar Maze Solving Algorithm |
# +------------------------------+

func solve_astar(heuristic):
	
	if pathFound:
		resetMaze()
	
	solving = true
	
	# Initialize 2D Grid for Astar
	var astargrid = AStarGrid2D.new()
	astargrid.region = get_used_rect()
	astargrid.cell_size = Vector2i(64, 64)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.default_compute_heuristic = heuristic
	astargrid.update()
	
	# Overlay maze walls onto Astar grid
	var tiles = get_used_cells(LAYER)
	for tile in tiles:
		if is_wall(tile):
			astargrid.set_point_solid(tile)
	
	# Solve maze using Astar, return list of coordinates
	path = astargrid.get_id_path(Vector2i(start_coords.x, start_coords.y), Vector2i(x_size-1, y_size-1))
	
	for coord in path:
		place_solved_path(coord)
		await get_tree().create_timer(Globals.delay).timeout
	
	pathFound = true
	Globals.enableSolveButtons.emit()
	solving = false
	Globals.currentMazeSolved.emit(timer)
	print("A* solving time: " + str(timer))
	timer = 0

# +--------------------------------------+
# | Breadth First Maze Solving Algorithm |
# +--------------------------------------+

func solve_bfs():
	
	# Reset maze if already solved
	if pathFound:
		resetMaze()
	
	solving = true
	
	# Create frontier and explored
	var frontier: Array[Vector2i] = [start_coords]
	var explored = []
	var solved = false
	
	while frontier.size() > 0 or not solved:
		var move = frontier.pop_back()
		
		if move == Vector2i(x_size-1, y_size-1):
			solved = true
			break
		
		for side in adjacent:
			var possible_move = move + side
			
			if possible_move not in explored and isValidMove(possible_move):
				frontier.append(possible_move)
				explored.append(possible_move)
				path.append(possible_move)
				place_solved_path(possible_move)
				await get_tree().create_timer(Globals.delay).timeout
	
	pathFound = true
	
	# Solving complete, reenable buttons
	Globals.enableSolveButtons.emit()
	
	# Pause timer, send time info, reset timer
	solving = false
	if isSecondMaze:
		Globals.secondMazeSolved.emit(timer)
	else:
		Globals.currentMazeSolved.emit(timer)
	print("BFS solving time: " + str(timer))
	timer = 0
