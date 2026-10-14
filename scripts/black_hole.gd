extends Node

var yaw := 0.0
var pitch := 0.14
var distance := 18.0
var target_yaw := 0.0
var target_pitch := 0.14
var target_distance := 18.0
var dragging := false
var paused := false
var muted := false
var quality := 1
var simulation_time := 0.0
var frame_count := 0
var capture_path := ""
var test_mode := false
var test_view := ""
var viewport: SubViewport
var render_rect: ColorRect
var material: ShaderMaterial
var display: TextureRect
var bloom: ShaderMaterial
var music: AudioStreamPlayer
var ui: Control
var info: Label
var status: Label
var eye := Vector3.ZERO
var camera_basis := Basis.IDENTITY

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
		if arg == "--self-test": test_mode = true
		if arg.begins_with("--view="): test_view = arg.trim_prefix("--view=")
	if not capture_path.is_empty():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600,900))
		paused = true
	_create_renderer()
	_create_music()
	_create_interface()
	if test_view == "top": pitch = 1.15
	if test_view == "close": distance = 10.0
	target_pitch = pitch
	target_distance = distance
	_resize()
	_update_camera()
	_update_status()
	get_viewport().size_changed.connect(_resize)

func _create_renderer() -> void:
	viewport = SubViewport.new()
	viewport.name = "CurvedLightRenderer"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	render_rect = ColorRect.new()
	render_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = load("res://shaders/black_hole.gdshader")
	material.set_shader_parameter("galaxy", load("res://assets/milky_way.jpg"))
	render_rect.material = material
	viewport.add_child(render_rect)
	display = TextureRect.new()
	display.name = "BlackHoleImage"
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloom = ShaderMaterial.new()
	bloom.shader = load("res://shaders/bloom.gdshader")
	bloom.set_shader_parameter("rendered_frame", viewport.get_texture())
	display.material = bloom
	add_child(display)

func _create_music() -> void:
	music = AudioStreamPlayer.new()
	music.name = "EventHorizonAmbient"
	var stream = load("res://audio/playstarz_music-space-ambient-435262.mp3").duplicate()
	stream.loop = true
	music.stream = stream
	music.volume_db = -45.0
	add_child(music)
	if test_mode:
		music.play()
	elif capture_path.is_empty():
		music.play()
		create_tween().tween_property(music,"volume_db",-3.0,3.0)

func _create_interface() -> void:
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	var heading := Label.new()
	heading.position = Vector2(30,24)
	heading.text = "EVENT HORIZON  /  事件视界"
	heading.add_theme_font_size_override("font_size",24)
	heading.modulate = Color(0.96,0.85,0.67,0.88)
	ui.add_child(heading)
	status = Label.new()
	status.position = Vector2(32,62)
	status.add_theme_font_size_override("font_size",14)
	status.modulate = Color(0.85,0.78,0.67,0.72)
	ui.add_child(status)
	info = Label.new()
	info.text = "鼠标拖动：环绕视角   滚轮：拉近 / 拉远   R：复位\n空格：暂停吸积盘   M：音乐开关   Q：画质切换\nH：隐藏文字   F11：全屏切换   Esc：退出\n非旋转黑洞引力透镜近似 · 吸积盘色彩与配乐为艺术表现"
	info.add_theme_font_size_override("font_size",15)
	info.modulate = Color(0.85,0.81,0.73,0.78)
	info.add_theme_color_override("font_shadow_color",Color.BLACK)
	info.add_theme_constant_override("shadow_offset_x",1)
	info.add_theme_constant_override("shadow_offset_y",1)
	ui.add_child(info)

func _resize() -> void:
	var screen := get_viewport().get_visible_rect().size
	if screen.x <= 0.0 or screen.y <= 0.0: return
	var widths := [960.0,1440.0,1920.0]
	var ratio := minf(widths[quality]/screen.x,1.0)
	viewport.size = Vector2i(maxi(320,int(screen.x*ratio)),maxi(180,int(screen.y*ratio)))
	render_rect.size = Vector2(viewport.size)
	display.size = screen
	ui.size = screen
	info.position = Vector2(30,screen.y-123)
	material.set_shader_parameter("resolution",Vector2(viewport.size))
	material.set_shader_parameter("step_limit",[140,200,260][quality])
	bloom.set_shader_parameter("render_size",Vector2(viewport.size))

func _update_camera() -> void:
	eye = Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera_basis = Basis.looking_at(-eye,Vector3.UP)
	material.set_shader_parameter("eye",eye)
	material.set_shader_parameter("camera_basis",camera_basis)
	material.set_shader_parameter("simulation_time",simulation_time)

func _update_status() -> void:
	var qualities := ["流畅","均衡","高清"]
	status.text = "Rs = 1  ·  距离 %.1f Rs  ·  %s  ·  音乐%s%s" % [distance,qualities[quality],"关闭" if muted else "开启","  ·  已暂停" if paused else ""]

func _process(delta: float) -> void:
	frame_count += 1
	var factor := 1.0-exp(-10.0*delta)
	yaw = lerpf(yaw,target_yaw,factor)
	pitch = lerpf(pitch,target_pitch,factor)
	distance = lerpf(distance,target_distance,factor)
	if not paused: simulation_time += minf(delta,0.1)
	_update_camera()
	if frame_count % 15 == 0: _update_status()
	if test_mode and frame_count == 4: _run_tests()
	if not capture_path.is_empty() and frame_count == 30:
		ui.visible = false
		_capture.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if not capture_path.is_empty(): return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = maxf(4.2,target_distance*0.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = minf(45.0,target_distance/0.9)
	elif event is InputEventMouseMotion and dragging:
		target_yaw -= event.relative.x*0.0045
		target_pitch = clampf(target_pitch+event.relative.y*0.0045,-1.45,1.45)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: get_tree().quit()
			KEY_R:
				target_yaw = 0.0
				target_pitch = 0.14
				target_distance = 18.0
			KEY_SPACE: paused = not paused
			KEY_M:
				muted = not muted
				music.stream_paused = muted
			KEY_Q:
				quality = (quality+1)%3
				_resize()
			KEY_H: ui.visible = not ui.visible
			KEY_F11:
				var mode := DisplayServer.window_get_mode()
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		_update_status()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(capture_path)
	print("CAPTURE_RESULT=",result," render=",viewport.size)
	get_tree().quit()

func _run_tests() -> void:
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	for i in range(100): _unhandled_input(wheel)
	assert(is_equal_approx(target_distance,4.2),"Near zoom limit")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for i in range(100): _unhandled_input(wheel)
	assert(is_equal_approx(target_distance,45.0),"Far zoom limit")
	dragging = true
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100,10000)
	_unhandled_input(motion)
	assert(target_yaw<0.0 and target_pitch<=1.45,"Orbit clamp")
	dragging = false
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_R
	_unhandled_input(key)
	assert(target_yaw==0.0 and is_equal_approx(target_distance,18.0),"Reset")
	key.keycode = KEY_SPACE
	_unhandled_input(key)
	var saved_time := simulation_time
	_process(0.1)
	assert(is_equal_approx(simulation_time,saved_time),"Pause")
	_unhandled_input(key)
	_process(0.1)
	assert(simulation_time>saved_time,"Resume")
	key.keycode = KEY_M
	_unhandled_input(key)
	assert(muted and music.stream_paused,"Mute")
	_unhandled_input(key)
	assert(not muted and not music.stream_paused,"Unmute")
	key.keycode = KEY_Q
	_unhandled_input(key)
	assert(quality==2,"Quality switching")
	var track := music.stream as AudioStreamWAV
	assert(track.loop_mode==AudioStreamWAV.LOOP_FORWARD and track.loop_end>track.loop_begin,"Loop configured")
	assert(is_equal_approx(track.get_length(),48.0),"Music duration")
	assert(eye.is_finite() and camera_basis.determinant()>0.99,"Finite camera")
	print("SELF_TEST_PASS: orbit, zoom, reset, pause, music mute, loop, quality")
	get_tree().quit()
