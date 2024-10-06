extends Node

# Constants for modes
const MODE_CLIENT = "client"
const MODE_SERVER = "server"


var mode = ""

func _ready():
	# Check the mode (using command-line arguments for example)
	mode = get_argument("--mode", MODE_CLIENT) # Default to client mode

	if mode == MODE_SERVER:
		start_server()
	else:
		start_client()

func start_server():
	# Load server initialization scripts
	var server = preload("res://src/server/main.gd").new()
	add_child(server) # Ensure it's part of the scene tree

	# Start the server logic
	server.start_server()
	print("Server started.")

func start_client():
	# Load client initialization scripts
	var client = preload("res://src/client/main.tscn").instantiate()
	add_child(client) # Ensure it's part of the scene tree

	# Start the client logic
	client.start_client()
	print("Client started.")

# Helper function to get command line arguments
func get_argument(arg_name: String, default_value: String) -> String:
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i].strip_edges().contains(arg_name):
			return args[i + 1].strip_edges()
	return default_value
