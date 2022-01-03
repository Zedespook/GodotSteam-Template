extends Node2D

enum lobby_status { Private, Friends, Public, Invisible }
enum search_distance { Close, Default, Far, Worldwide }

onready var steam_username: Label = $SteamName
onready var set_lobby_name: TextEdit = $Create/LobbySetter
onready var get_lobby_name: Label = $Chat/LobbyName
onready var lobby_chat_text: RichTextLabel = $Chat/RichTextLabel
onready var available_lobbies_window: PopupPanel = $LobbyListPopup
onready var available_lobbies_list: VBoxContainer = $LobbyListPopup/Panel/Scroll/VBox
onready var player_count: Label = $Players/Label
onready var player_list: RichTextLabel = $Players/RichTextLabel
onready var chat_input: TextEdit = $Message/TextEdit

# -> Godot functions <-


func _ready() -> void:
    steam_username.text = Globals.STEAM_USERNAME

    var _connect: int = Steam.connect("lobby_created", self, "_on_Lobby_Created")
    _connect = Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
    _connect = Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
    _connect = Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
    _connect = Steam.connect("lobby_message", self, "_on_Lobby_Message")
    _connect = Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
    _connect = Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
    _connect = Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")

    _check_Command_Line()


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _send_Chat_Message()


# -> Self-made functions <-


func _create_Lobby() -> void:
    if Globals.LOBBY_ID == 0:
        Steam.createLobby(lobby_status.Public, 4)


func _join_Lobby(lobbyID: int) -> void:
    available_lobbies_window.hide()
    var lobby_name = Steam.getLobbyData(lobbyID, "name")
    _display_message("Joining lobby " + str(lobby_name) + "...")

    Globals.LOBBY_MEMBERS.clear()
    Steam.joinLobby(lobbyID)


func _get_Lobby_Members() -> void:
    Globals.LOBBY_MEMBERS.clear()
    var MEMBERS: int = Steam.getNumLobbyMembers(Globals.LOBBY_ID)

    for MEMBER in range(0, MEMBERS):
        var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(Globals.LOBBY_ID, MEMBER)
        var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
        _add_Player_List(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)


func _add_Player_List(steam_id: int, steam_name: String):
    Globals.LOBBY_MEMBERS.append({"steam_id": steam_id, "steam_name": steam_name})

    player_list.clear()
    var tmp: int = 0

    for MEMBER in Globals.LOBBY_MEMBERS:
        player_list.add_text(str(MEMBER["steam_name"]) + "\n")
        tmp += 1
        player_count.text = "Players (" + str(tmp) + ")"


func _send_Chat_Message() -> void:
    var MESSAGE: String = chat_input.text
    var SENT: bool = Steam.sendLobbyChatMsg(Globals.LOBBY_ID, MESSAGE)

    if not SENT:
        _display_message("ERROR: Chat message failed to send.")

    chat_input.text = ""


func _leave_Lobby() -> void:
    if Globals.LOBBY_ID != 0:
        _display_message("Leaving lobby...")
        Steam.leaveLobby(Globals.LOBBY_ID)

        Globals.LOBBY_ID = 0

        get_lobby_name.text = "Lobby Name"
        player_count.text = "Players (0)"
        player_list.clear()

        for MEMBERS in Globals.LOBBY_MEMBERS:
            var _tmp: int = Steam.closeP2PSessionWithUser(MEMBERS["steam_id"])

        Globals.LOBBY_MEMBERS.clear()


func _start_game() -> void:
    if Globals.LOBBY_MEMBERS == []:
        _display_message("You haven't joined/made a lobby yet.")
        return

    Globals.send_P2P_Packet("all", {"message": "start_game"})
    print("Game starting packet sent to all players.")

    # -> Load the game locally
    var _load_game = get_tree().change_scene("res://source/game/game.tscn")


func _display_message(message: String) -> void:
    lobby_chat_text.add_text("\n" + str(message))


# -> GodotSteam signal hooks <-


func _on_Lobby_Created(connect: int, lobbyID: int) -> void:
    if connect == 1:
        Globals.LOBBY_ID = lobbyID

        # -> Set and display lobby name
        _display_message("Created lobby: " + set_lobby_name.text)
        var _set_lobby_data: bool = Steam.setLobbyData(lobbyID, "name", set_lobby_name.text)
        var lobby_name = Steam.getLobbyData(lobbyID, "name")
        get_lobby_name.text = str(lobby_name)

        var RELAY: bool = Steam.allowP2PPacketRelay(true)
        print("Allowing Steam to be relay backup: " + str(RELAY))


func _on_Lobby_Joined(lobbyID: int, _permissions: int, _locked: bool, _response: int) -> void:
    Globals.LOBBY_ID = lobbyID

    var lobby_name = Steam.getLobbyData(lobbyID, "name")
    get_lobby_name.text = str(lobby_name)
    _get_Lobby_Members()

    Globals.make_P2P_Handshake()


func _on_Lobby_Join_Requested(lobbyID: int, friendID: int) -> void:
    var OWNER_NAME: String = Steam.getFriendPersonaName(friendID)
    _display_message("Joining " + str(OWNER_NAME) + "'s lobby...")
    _join_Lobby(lobbyID)


func _on_Lobby_Data_Update(success, lobbyID, memberID, key):
    print(
        (
            "Success: "
            + str(success)
            + ", Lobby ID: "
            + str(lobbyID)
            + ", Member ID: "
            + str(memberID)
            + ", Key: "
            + str(key)
        )
    )


func _on_Lobby_Chat_Update(_lobbyID: int, _changedID: int, makingChangeID: int, chatState: int) -> void:
    var CHANGER: String = Steam.getFriendPersonaName(makingChangeID)

    if chatState == 1:
        _display_message(str(CHANGER) + " has joined the lobby.")
    elif chatState == 2:
        _display_message(str(CHANGER) + " has left the lobby.")
    elif chatState == 8:
        _display_message(str(CHANGER) + " has been kicked from the lobby.")
    elif chatState == 16:
        _display_message(str(CHANGER) + " has been banned from the lobby.")
    else:
        _display_message(str(CHANGER) + " did... something.")

    _get_Lobby_Members()


func _on_Lobby_Match_List(lobbies: Array) -> void:
    for LOBBY in lobbies:
        var LOBBY_NAME: String = Steam.getLobbyData(LOBBY, "name")
        var LOBBY_MEMBERS: int = Steam.getNumLobbyMembers(LOBBY)
        var LOBBY_BUTTON = Button.new()

        LOBBY_BUTTON.set_text(
            (
                "Lobby "
                + str(LOBBY)
                + ": "
                + str(LOBBY_NAME)
                + " - ["
                + str(LOBBY_MEMBERS)
                + "] Player(s)"
            )
        )

        LOBBY_BUTTON.set_size(Vector2(800, 50))
        LOBBY_BUTTON.set_name("lobby_" + str(LOBBY))
        var _tmp: int = LOBBY_BUTTON.connect("pressed", self, "_join_Lobby", [LOBBY])

        available_lobbies_list.add_child(LOBBY_BUTTON)


func _on_Lobby_Message(_result, user, message: String, _type):
    var SENDER = Steam.getFriendPersonaName(user)
    _display_message(str(SENDER) + " : " + str(message))


# -> Buttons <-


func _on_Create_pressed() -> void:
    _create_Lobby()


func _on_Join_pressed() -> void:
    available_lobbies_window.popup()

    Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
    _display_message("Searching for lobbies...")

    Steam.requestLobbyList()


func _on_Start_pressed() -> void:
    _start_game()


func _on_Leave_pressed() -> void:
    _leave_Lobby()


func _on_Message_pressed() -> void:
    _send_Chat_Message()


func _on_Close_pressed() -> void:
    available_lobbies_window.hide()


func _check_Command_Line() -> void:
    var ARGUMENTS = OS.get_cmdline_args()

    if ARGUMENTS.size() > 0:
        for ARGUMENT in ARGUMENTS:
            print("Command line: " + str(ARGUMENT))

            if Globals.LOBBY_INVITE_ARG:
                _join_Lobby(int(ARGUMENT))

            if ARGUMENT == "+connect_lobby":
                Globals.LOBBY_INVITE_ARG = true
