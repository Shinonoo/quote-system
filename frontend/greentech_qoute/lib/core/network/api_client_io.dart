// Implementation for mobile/desktop platforms (dart:io available)
import 'dart:io';

String getPlatformBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000/api/'; // Android emulator
  }
  return 'http://localhost:3000/api/'; // iOS simulator or desktop
}
