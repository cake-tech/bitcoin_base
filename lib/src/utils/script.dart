import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';

bool isDefinedHashType(sighash) {
  final hashTypeMod = sighash & ~BitcoinOpCodeConst.sighashAnyoneCanPay;
  return hashTypeMod > BitcoinOpCodeConst.sighashAll &&
      hashTypeMod < BitcoinOpCodeConst.sighashSingle;
}

bool bip66check(buffer) {
  if (buffer.length < 8) return false;
  if (buffer.length > 72) return false;
  if (buffer[0] != 0x30) return false;
  if (buffer[1] != buffer.length - 2) return false;
  if (buffer[2] != 0x02) return false;

  var lenR = buffer[3];
  if (lenR == 0) return false;
  if (5 + lenR >= buffer.length) return false;
  if (buffer[4 + lenR] != 0x02) return false;

  var lenS = buffer[5 + lenR];
  if (lenS == 0) return false;
  if ((6 + lenR + lenS) != buffer.length) return false;

  if (buffer[4] & 0x80 != 0) return false;
  if (lenR > 1 && (buffer[4] == 0x00) && buffer[5] & 0x80 == 0) return false;

  if (buffer[lenR + 6] & 0x80 != 0) return false;
  if (lenS > 1 && (buffer[lenR + 6] == 0x00) && buffer[lenR + 7] & 0x80 == 0) return false;
  return true;
}

bool isCanonicalScriptSignature(List<int> buffer) {
  if (!isDefinedHashType(buffer[buffer.length - 1])) return false;
  return bip66check(buffer.sublist(0, buffer.length - 1));
}
