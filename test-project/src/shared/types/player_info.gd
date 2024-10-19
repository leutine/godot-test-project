class_name PlayerInfo

var id: int = -1
var label: String = "Player"
var color: Color = Color.BLACK


func to_dict() -> Dictionary:
	return {"id": id, "label": label, "color": color}


func to_json() -> String:
	return JSON.stringify(self)


static func from_dict(dict: Dictionary) -> PlayerInfo:
	var player_info = PlayerInfo.new()
	player_info.id = dict.id
	player_info.label = dict.label
	player_info.color = dict.color
	return player_info


static func from_json(data: String) -> PlayerInfo:
	return JSON.parse_string(data) as PlayerInfo
