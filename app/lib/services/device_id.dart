import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _deviceIdKey = 'telemetry_device_id';

/// Random, anonymous id for this install (a UUID made on first use, not
/// tied to any identity). Shared by telemetry, word reports and account
/// linking so the backend sees one device.
Future<String> deviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(_deviceIdKey);
  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString(_deviceIdKey, id);
  }
  return id;
}
