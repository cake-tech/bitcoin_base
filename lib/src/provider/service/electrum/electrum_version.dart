import 'package:bitcoin_base/src/exception/exception.dart';

class ElectrumVersion {
  final int major;
  final int minor;
  final int patch;

  const ElectrumVersion(this.major, this.minor, this.patch);

  factory ElectrumVersion.fromStr(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw BitcoinBasePluginException('Invalid version string: $version');
    }

    return ElectrumVersion(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  int compareTo(ElectrumVersion other) {
    if (major > other.major) {
      return 1;
    } else if (major < other.major) {
      return -1;
    }

    if (major == other.major) {
      if (minor > other.minor) {
        return 1;
      } else if (minor < other.minor) {
        return -1;
      }
    }

    if (minor == other.minor) {
      if (patch > other.patch) {
        return 1;
      } else if (patch < other.patch) {
        return -1;
      }
    }

    return 0;
  }

  @override
  String toString() {
    return '$major.$minor.$patch';
  }
}
