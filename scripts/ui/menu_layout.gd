extends RefCounted
## Shared placeholder layout for menus while illustrated UI is out of scope.

static func create(parent: Control, title: String, subtitle: String = "") -> VBoxContainer:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.047, 0.09, 0.94)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 420.0
	content.add_theme_constant_override("separation", 14)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content)

	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 44)
	heading.add_theme_color_override("font_color", Color("#f5d99b"))
	content.add_child(heading)
	if not subtitle.is_empty():
		var detail := Label.new()
		detail.text = subtitle
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 18)
		detail.add_theme_color_override("font_color", Color("#c6cde0"))
		content.add_child(detail)
	return content


static func add_button(parent: VBoxContainer, text: String, action: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(340.0, 48.0)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
