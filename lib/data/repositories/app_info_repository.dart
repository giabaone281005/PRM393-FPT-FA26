import 'package:package_info_plus/package_info_plus.dart';

/// Reads installed package metadata so build-name/build-number overrides work.
class AppInfoRepository {
  Future<String> versionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isEmpty) return 'Chưa đọc được phiên bản';
      return 'Phiên bản ${info.version}${info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})'}';
    } catch (_) {
      return 'Chưa đọc được phiên bản';
    }
  }
}
