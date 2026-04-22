import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    print('SharedPreferences loaded: ${prefs.runtimeType}');
  } catch (e) {
    print('Error: $e');
  }
}
