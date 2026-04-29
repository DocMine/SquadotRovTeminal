extends Node

var manager: GdSerialManager = GdSerialManager.new()

var portsInfo:Dictionary = {}

signal SerialPortUpdated(infodic:Dictionary)

func _ready():
	manager.data_received.connect(_on_data)
	manager.port_disconnected.connect(_on_disconnect)
	print()

	# 模式 0：RAW（立即发送所有数据块）
	# 模式 1：行缓冲（等待 \n）
	# 模式 2：自定义分隔符
	if manager.open("COM3", 9600, 1000):
		print("已连接到 COM3")
		
func updateports():
	# 刷新串口信息, 串口的id从1000开始计算
	# 这个id主要用于弹出菜单的定位，也可用于反查串口信息
	var ComId:int = 1000
	portsInfo.clear()
	var rawdic:Dictionary = manager.list_ports()
	for SrialIndex:int in rawdic.keys():
		print("update", rawdic[SrialIndex])
		portsInfo.set(ComId,rawdic[SrialIndex])
		ComId += 1
	SerialPortUpdated.emit(portsInfo)

func _process(_delta):
	# 此调用触发上述信号
	manager.poll_events()

func _on_data(port: String, data: PackedByteArray):
	print("来自 ", port, " 的数据：", data.get_string_from_utf8())

func _on_disconnect(port: String):
	print("与 ", port, " 的连接已断开")
