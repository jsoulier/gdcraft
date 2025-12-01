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
