import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  AppInfo({
    required this.version,
    required this.buildNumber,
    required this.fullVersion,
  });

  final String version;
  final String buildNumber;
  final String fullVersion;
}

Future<AppInfo> getAppInfo() async {
  final info = await PackageInfo.fromPlatform();

  return AppInfo(
    version: info.version,
    buildNumber: info.buildNumber,
    fullVersion: '${info.version}+${info.buildNumber}',
  );
}
