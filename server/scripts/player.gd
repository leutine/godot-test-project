extends CharacterBody3D

# Set by the authority, synchronized on spawn.
@onready var input = $PlayerInput
@export var network_id := 1:
	set(id):
		network_id = id
		# Give authority over the player input to the appropriate peer.
		#input.set_multiplayer_authority(id)


@export var name_label_text := "Player":
	set(text):
		name_label_text = text


@export var color := Color.BLACK:
	set(new_color):
		color = new_color
