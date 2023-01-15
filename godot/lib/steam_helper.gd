extends Node

var OWNED: bool = false
var ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ""
var LOBBY_DATA
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var LOBBY_INVITE_ARG: bool = false


func _ready() -> void:
	var INIT: Dictionary = Steam.steamInit()

	if INIT["status"] != 1:
		print("Failed to init Steam." + str(INIT["verbal"]) + " Shutting down...")
		get_tree().quit()

	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()

	if not OWNED:
		print("User does not own this game.")
		get_tree().quit()

	var _tmp: int = Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	_tmp = Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")


func _process(_delta: float) -> void:
	Steam.run_callbacks()

	for pack in Steam.getAvailableP2PPacketSize(0):
		_read_P2P_Packet()


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	if PACKET_SIZE == 0:
		return

	var PACKET = Steam.readP2PPacket(PACKET_SIZE, 0)

	if PACKET.empty():
		print("WARNING: read an empty packet with non-zero size!")

	var _PACKET_ID: String = str(PACKET.steamIDRemote)
	var _PACKET_CODE: String = str(PACKET.data[0])

	var READABLE = bytes2var(PACKET.data.subarray(1, PACKET_SIZE - 1))
	PacketManager.handle_packet(READABLE.values()[0])


func send_P2P_Packet(target: String, packet_data: Dictionary) -> void:
	var SEND_TYPE: int = 2
	var CHANNEL: int = 0
	var _DATA: PoolByteArray

	_DATA.append(256)
	_DATA.append_array(var2bytes(packet_data))

	if target == "all":
		if LOBBY_MEMBERS.size() > 1:
			for MEMBER in LOBBY_MEMBERS:
				if MEMBER["steam_id"] != STEAM_ID:
					var _send_to_all: int = Steam.sendP2PPacket(
						MEMBER["steam_id"], _DATA, SEND_TYPE, CHANNEL
					)
		else:
			var _send_to_target: int = Steam.sendP2PPacket(int(target), _DATA, SEND_TYPE, CHANNEL)


func make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")
	send_P2P_Packet("all", {"message": "handshake", "from": STEAM_ID})


func _on_P2P_Session_Request(remoteID: int) -> void:
	var _REQUESTER: String = Steam.getFriendPersonaName(remoteID)
	var _tmp: bool = Steam.acceptP2PSessionWithUser(remoteID)
	make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(lobbyID: int, session_error: int) -> void:
	match session_error:
		0:
			print("WARNING: Session failure with " + str(lobbyID) + " [no error given].")
		1:
			print(
				(
					"WARNING: Session failure with "
					+ str(lobbyID)
					+ " [target user not running the same game]."
				)
			)
		2:
			print(
				(
					"WARNING: Session failure with "
					+ str(lobbyID)
					+ " [local user doesn't own app / game]."
				)
			)
		3:
			print(
				(
					"WARNING: Session failure with "
					+ str(lobbyID)
					+ " [target user isn't connected to Steam]."
				)
			)
		4:
			print(
				(
					"WARNING: Session failure with "
					+ str(lobbyID)
					+ " [target user doesn't own app / game]."
				)
			)
		5:
			print(
				(
					"WARNING: Session failure with "
					+ str(lobbyID)
					+ " [target user is not running the same game]."
				)
			)
		_:
			print("WARNING: Session failure with " + str(lobbyID) + " [unknown error].")
