extends Node
## Rewarded-ad facade. The game only ever talks to this class, so wiring the real
## Google AdMob plugin later touches ONE place (_show_native).
##
## Per the project plan, ads stay OFF until retention is validated:
##  - release builds: is_available() is false, so the UI never shows ad buttons
##  - debug builds: ads are simulated (1 s delay, then the reward) so the flows
##    (revive, double coins) can be tested without any SDK

signal reward_granted(kind: String)
signal reward_failed(kind: String)

## Flip to true once the AdMob plugin is installed and _show_native is filled in.
const ADS_ENABLED := false


func is_available() -> bool:
	return ADS_ENABLED or OS.is_debug_build()


func show_rewarded(kind: String) -> void:
	if not is_available():
		reward_failed.emit(kind)
		return
	if ADS_ENABLED:
		_show_native(kind)
		return
	await get_tree().create_timer(1.0).timeout
	reward_granted.emit(kind)


func _show_native(kind: String) -> void:
	# Example once a plugin is installed (API differs per plugin - follow its docs):
	#   var ad := RewardedAd.new()
	#   ad.on_user_earned_reward.connect(func(_r): reward_granted.emit(kind))
	#   ad.on_failed_to_load.connect(func(_e): reward_failed.emit(kind))
	#   ad.load("ca-app-pub-xxxxxxxx/yyyyyyyy"); ad.show()
	push_warning("AdManager: ADS_ENABLED is true but _show_native is not implemented.")
	reward_failed.emit(kind)
