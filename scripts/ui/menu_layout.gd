extends RefCounted
## Illustrated atmospheric layout for Title, Hub, Pause, and Ending screens.

static func create(parent: Control, title: String, subtitle: String = "") -> VBoxContainer:
	var is_ending := title == "The Last Wick"
	var is_pause := title == "Paused"

	var background := ColorRect.new()
	if is_pause:
		background.color = Color(0.035, 0.047, 0.09, 0.86)
	elif is_ending:
		background.color = Color(0.08, 0.07, 0.16, 1.0)
	else:
		background.color = Color(0.04, 0.05, 0.11, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(background)

	# Illustrated scenic layers behind non-pause menus
	if not is_pause:
		_add_illustrated_backdrop(background, is_ending)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.09, 0.18, 0.82 if not is_ending else 0.72)
	card_style.border_color = Color(0.95, 0.78, 0.45, 0.42)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(8)
	card_style.content_margin_left = 38.0
	card_style.content_margin_right = 38.0
	card_style.content_margin_top = 32.0
	card_style.content_margin_bottom = 32.0
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 420.0
	content.add_theme_constant_override("separation", 14)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(content)

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


static func _add_illustrated_backdrop(background: Control, is_ending: bool) -> void:
	var canvas := Node2D.new()
	canvas.name = "MenuArtCanvas"
	background.add_child(canvas)

	# Warm dawn horizon band (expanded and brighter on the Ending screen)
	var horizon := Polygon2D.new()
	horizon.color = Color(0.42, 0.26, 0.34, 0.48) if is_ending else Color(0.14, 0.16, 0.32, 0.45)
	horizon.polygon = PackedVector2Array([
		Vector2(0, 220 if is_ending else 340),
		Vector2(1280, 220 if is_ending else 340),
		Vector2(1280, 720),
		Vector2(0, 720),
	])
	canvas.add_child(horizon)

	# Radiant central sun/lantern aura
	var aura := Polygon2D.new()
	var aura_center := Vector2(640, 440 if is_ending else 500)
	var aura_radius := 360.0 if is_ending else 220.0
	aura.color = Color(1.0, 0.80, 0.42, 0.25 if is_ending else 0.12)
	var aura_pts := PackedVector2Array()
	for i in 24:
		var a := float(i) * TAU / 24.0
		aura_pts.append(aura_center + Vector2(cos(a), sin(a)) * aura_radius)
	aura.polygon = aura_pts
	canvas.add_child(aura)

	# Distant illustrated ruin ridge
	var ridge := Polygon2D.new()
	ridge.color = Color("#12172e") if not is_ending else Color("#1c1a33")
	ridge.polygon = PackedVector2Array([
		Vector2(0, 720), Vector2(0, 520), Vector2(140, 460),
		Vector2(220, 490), Vector2(230, 360), Vector2(265, 350),
		Vector2(275, 485), Vector2(460, 515), Vector2(640, 470),
		Vector2(820, 515), Vector2(1005, 485), Vector2(1015, 350),
		Vector2(1050, 360), Vector2(1060, 490), Vector2(1140, 460),
		Vector2(1280, 520), Vector2(1280, 720),
	])
	canvas.add_child(ridge)

	# Drifting golden embers
	var embers := CPUParticles2D.new()
	embers.position = Vector2(640, 680)
	embers.amount = 38 if is_ending else 22
	embers.lifetime = 4.5
	embers.preprocess = 2.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(600, 40)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 14.0
	embers.initial_velocity_max = 32.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.5
	embers.color = Color(1.0, 0.84, 0.48, 0.55 if is_ending else 0.35)
	canvas.add_child(embers)


static func add_button(parent: VBoxContainer, text: String, action: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(340.0, 48.0)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#f5e3b8"))
	button.add_theme_color_override("font_hover_color", Color("#fff4d6"))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.56, 0.68, 0.55))

	var normal_box := StyleBoxFlat.new()
	normal_box.bg_color = Color(0.13, 0.16, 0.28, 0.90)
	normal_box.border_color = Color(0.85, 0.70, 0.42, 0.45)
	normal_box.set_border_width_all(1)
	normal_box.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal_box)

	var hover_box := normal_box.duplicate() as StyleBoxFlat
	hover_box.bg_color = Color(0.20, 0.24, 0.40, 0.96)
	hover_box.border_color = Color(1.0, 0.84, 0.52, 0.85)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_stylebox_override("focus", hover_box)

	button.pressed.connect(action)
	parent.add_child(button)
	return button
