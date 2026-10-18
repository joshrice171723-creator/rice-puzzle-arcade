@tool
extends EditorPlugin

var android_export: EditorExportPlugin

func _enter_tree() -> void:
	android_export = NightfallExport.new()
	add_export_plugin(android_export)

func _exit_tree() -> void:
	remove_export_plugin(android_export)

class NightfallExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "NightfallTestAds"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.gms:play-services-ads:25.5.0", "com.google.android.ump:user-messaging-platform:4.0.0"])

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.NightfallAds" android:value="com.joshuarice.nightfallproof.NightfallAds"/><meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>'
