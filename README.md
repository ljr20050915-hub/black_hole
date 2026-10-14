# EVENT HORIZON / 黑洞

双击 Run_BlackHole.bat 运行；或在 Godot 4.6.3 导入 project.godot 后按 F5。
独立项目，原有地球项目不受影响。全屏启动、离线运行。

鼠标左键/右键拖动：环绕观察；滚轮：拉近 / 拉远；R：复位。
空格：暂停吸积盘；M：音乐开关；Q：流畅 / 均衡 / 高清。
H：隐藏文字；F11：全屏切换；Esc：退出。
默认均衡画质，内部渲染宽度最多 1440 像素；高清最多 1920。
按 Q 调整性能与清晰度，窗口仍保持全屏原生大小。

## 画面原理
每个像素的光线通过中心引力场数值积分弯曲，银河背景和吸积盘共同参与透镜。
黑色中心吸收穿过事件视界的光线；盘的背面可形成上下弧线和多重影像。
非旋转黑洞模型以史瓦西半径 Rs=1 为单位，盘从 3 Rs（最内稳定圆轨道）延伸到 9 Rs。
盘温度、轨道运动、引力红移与多普勒增亮采用示意模型。
这是实时近似可视化，未求解完整 Kerr 度规，也不用于科研数值测量。
吸积盘为程序纹理，不是真实观测照片。旋转与色彩用于直观展示。

## 音乐
原创合成氛围音 Event Horizon，48 秒，44.1kHz 双声道，周期合成确保连续循环。
低频持续音、缓慢脉动与轻微不协和泛音；启动时淡入，可按 M 关闭。
太空真空中不会传播这种声音，音乐仅用于氛围。
路径：audio/event_horizon_loop.wav。
替换为同名 WAV 后重新导入，默认按完整音轨循环。

## 背景与署名
8K 银河背景：Solar System Scope / INOVE, Stars + Milky Way。
https://www.solarsystemscope.com/textures/
https://www.solarsystemscope.com/textures/download/8k_stars_milky_way.jpg
许可 CC BY 4.0：https://creativecommons.org/licenses/by/4.0/
来源图保留下载内容，运行时由着色器调整亮度和方向。
背景位置：assets/milky_way.jpg。

参考：NASA 黑洞引力透镜可视化
https://www.nasa.gov/universe/nasa-visualization-shows-a-black-holes-warped-world/

## 参数
scripts/black_hole.gd：视角、缩放范围、音乐音量、画质。
shaders/black_hole.gdshader：盘内外半径、亮度、光线积分、引力强度。
shaders/bloom.gdshader：光晕 bloom_strength。