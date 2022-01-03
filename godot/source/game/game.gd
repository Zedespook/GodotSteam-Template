extends Node2D


func _ready() -> void:
    add_to_group("Game")

    var add_button: Button = $CanvasLayer/UI/VBoxContainer/Add
    var _connect: int = add_button.connect("pressed", self, "_button_pressed")


func _button_pressed():
    add_to_counter()
    Globals.send_P2P_Packet("all", {"message": "add_counter"})


func add_to_counter() -> void:
    var counter: Label = $CanvasLayer/UI/VBoxContainer/Counter
    counter.text = str(int(counter.text) + 1)
