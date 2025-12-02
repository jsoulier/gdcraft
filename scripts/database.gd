class_name Database
extends Node

@export var path = "user://gdcraft.sqlite"
var _database: SQLite = null
var _mutex = Mutex.new()

func _init() -> void:
	_database = SQLite.new()
	_database.path = path
	_database.verbosity_level = SQLite.VerbosityLevel.NORMAL
	if not _database.open_db():
		push_error("Failed to open database: " + path)
	var blocks_table = """
		CREATE TABLE IF NOT EXISTS blocks (
			chunk_x INTEGER NOT NULL,
			chunk_y INTEGER NOT NULL,
			chunk_z INTEGER NOT NULL,
			block_x INTEGER NOT NULL,
			block_y INTEGER NOT NULL,
			block_z INTEGER NOT NULL,
			type INTEGER NOT NULL,
			PRIMARY KEY (chunk_x, chunk_y, chunk_z, block_x, block_y, block_z)
		);
	"""
	if not _database.query(blocks_table):
		push_error("Failed to create blocks table")
	var blocks_index = """
		CREATE INDEX IF NOT EXISTS blocks_index
		ON blocks (chunk_x, chunk_y, chunk_z);
	"""
	if not _database.query(blocks_index):
		push_error("Failed to create blocks index")
	var players_table = """
		CREATE TABLE IF NOT EXISTS players (
			id INTEGER PRIMARY KEY,
			position_x INTEGER NOT NULL,
			position_y INTEGER NOT NULL,
			position_z INTEGER NOT NULL,
			rotation_x INTEGER NOT NULL,
			rotation_y INTEGER NOT NULL,
			rotation_z INTEGER NOT NULL
		);
	"""
	if not _database.query(players_table):
		push_error("Failed to create players table")
	var players_index = """
		CREATE INDEX IF NOT EXISTS players_index
		ON players (id);
	"""
	if not _database.query(players_index):
		push_error("Failed to create players index")
	var sky_table = """
		CREATE TABLE IF NOT EXISTS sky (
			id INTEGER PRIMARY KEY,
			time_of_day INTEGER NOT NULL
		);
	"""
	if not _database.query(sky_table):
		push_error("Failed to create sky table")
	var sky_index = """
		CREATE INDEX IF NOT EXISTS sky_index
		ON sky (id);
	"""
	if not _database.query(sky_index):
		push_error("Failed to create sky index")

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_mutex.lock()
		_database.close_db()
		_database = null
		_mutex.unlock()

func set_block(chunk: Vector3i, block: Vector3i, type: Block.Type) -> void:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return
	if type == Block.Type.EMPTY:
		var sql = """
			DELETE FROM blocks
			WHERE chunk_x=? AND chunk_y=? AND chunk_z=?
			  AND block_x=? AND block_y=? AND block_z=?;
		"""
		var bindings = [chunk.x, chunk.y, chunk.z, block.x, block.y, block.z]
		if not _database.query_with_bindings(sql, bindings):
			push_error("Failed to remove block")
	else:
		var sql = """
			INSERT INTO blocks
			(chunk_x, chunk_y, chunk_z, block_x, block_y, block_z, type)
			VALUES (?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(chunk_x, chunk_y, chunk_z, block_x, block_y, block_z)
			DO UPDATE SET type = excluded.type;
		"""
		var bindings = [chunk.x, chunk.y, chunk.z, block.x, block.y, block.z, type]
		if not _database.query_with_bindings(sql, bindings):
			push_error("Failed to set block")
	_mutex.unlock()

func get_blocks(chunk: Vector3i) -> Array:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return []
	var sql = """
		SELECT block_x, block_y, block_z, type
		FROM blocks
		WHERE chunk_x=? AND chunk_y=? AND chunk_z=?;
	"""
	var bindings = [chunk.x, chunk.y, chunk.z]
	if not _database.query_with_bindings(sql, bindings):
		push_error("Failed to get blocks")
		_mutex.unlock()
		return []
	var result = _database.query_result.duplicate(true)
	_mutex.unlock()
	return result

func save_player(player: Player, id: int) -> void:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return
	var sql = """
		INSERT INTO players
		(position_x, position_y, position_z, rotation_x, rotation_y, rotation_z, id)
		VALUES (?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id)
		DO UPDATE SET
			position_x = excluded.position_x,
			position_y = excluded.position_y,
			position_z = excluded.position_z,
			rotation_x = excluded.rotation_x,
			rotation_y = excluded.rotation_y,
			rotation_z = excluded.rotation_z;
	"""
	var position = player.position
	var rotation = player.rotation
	var bindings = [position.x, position.y, position.z, rotation.x, rotation.y, rotation.z, id]
	if not _database.query_with_bindings(sql, bindings):
		push_error("Failed to save player")
	_mutex.unlock()

func load_player(player: Player, id: int) -> void:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return
	var sql = """
		SELECT position_x, position_y, position_z,
			   rotation_x, rotation_y, rotation_z
		FROM players
		WHERE id = ?;
	"""
	var bindings = [id]
	if not _database.query_with_bindings(sql, bindings):
		push_error("Failed to load player")
		_mutex.unlock()
		return
	var result = _database.query_result
	if result.is_empty():
		print("Failed to load player")
		_mutex.unlock()
		return
	result = result[0]
	player.position = Vector3(result.position_x, result.position_y, result.position_z)
	player.rotation = Vector3(result.rotation_x, result.rotation_y, result.rotation_z)
	_mutex.unlock()

func save_sky(sky: GDCraftSky) -> void:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return
	var sql = """
		INSERT INTO sky
		(time_of_day, id)
		VALUES (?, ?)
		ON CONFLICT(id)
		DO UPDATE SET time_of_day = excluded.time_of_day;
	"""
	var bindings = [sky.time_of_day, 0]
	if not _database.query_with_bindings(sql, bindings):
		push_error("Failed to save sky")
	_mutex.unlock()

func load_sky(sky: GDCraftSky) -> void:
	_mutex.lock()
	if _database == null:
		_mutex.unlock()
		return
	var sql = """
		SELECT time_of_day
		FROM sky
		WHERE id = ?;
	"""
	var bindings = [0]
	if not _database.query_with_bindings(sql, bindings):
		push_error("Failed to load sky")
		_mutex.unlock()
		return
	var result = _database.query_result
	if result.is_empty():
		print("Failed to load sky")
		_mutex.unlock()
		return
	result = result[0]
	sky.time_of_day = result.time_of_day
	_mutex.unlock()
