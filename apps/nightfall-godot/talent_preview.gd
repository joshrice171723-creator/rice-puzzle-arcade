extends RefCounted
## Read-only view of the exact same definitions and ranks as the spending tree.
const TreeUI = preload("res://skill_tree_ui.gd")
static func show_page(home: Control) -> void:
 TreeUI.show_page(home,true)
