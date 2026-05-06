extends Node
class_name AdsManager

func show_interstitial() -> void:
	print("[AdsManager Mock] show_interstitial()")

func show_rewarded_continue() -> bool:
	print("[AdsManager Mock] show_rewarded_continue()")
	return true

func show_banner() -> void:
	print("[AdsManager Mock] show_banner()")

func hide_banner() -> void:
	print("[AdsManager Mock] hide_banner()")
