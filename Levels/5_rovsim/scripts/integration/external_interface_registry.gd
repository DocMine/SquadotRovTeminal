## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ExternalInterfaceRegistry
extends RefCounted

const INTERFACE_UDP: String = "udp"
const INTERFACE_TCP: String = "tcp"
const INTERFACE_MAVLINK: String = "mavlink"
const INTERFACE_ROS2: String = "ros2"


static func get_supported_interfaces() -> PackedStringArray:
	return PackedStringArray([INTERFACE_UDP, INTERFACE_TCP, INTERFACE_MAVLINK, INTERFACE_ROS2])


static func build_placeholder_status(interface_id: String) -> Dictionary:
	return {
		"interface_id": interface_id,
		"enabled": false,
		"connected": false,
		"last_error": "",
	}
