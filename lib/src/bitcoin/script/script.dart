import 'package:bitcoin_base_old/src/bitcoin/address/address.dart';
import 'package:bitcoin_base_old/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base_old/src/models/network.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// A Script contains just a list of OP_CODES and also knows how to serialize into bytes
///
/// [script] the list with all the script OP_CODES and data
class Script {
  Script({required List<dynamic> script})
      : assert(() {
          for (final i in script) {
            if (i is! String && i is! int) return false;
          }
          return true;
        }(),
            "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list."),
        script = List.unmodifiable(script);
  final List<dynamic> script;

  static Script fromRaw({List<int>? byteData, String? hexData, bool hasSegwit = false}) {
    List<String> commands = [];
    int index = 0;
    final scriptBytes = byteData ?? (hexData != null ? BytesUtils.fromHexString(hexData) : null);
    if (scriptBytes == null) {
      throw ArgumentError("Invalid script");
    }
    while (index < scriptBytes.length) {
      int byte = scriptBytes[index];
      if (BitcoinOpCodeConst.CODE_OPS.containsKey(byte)) {
        commands.add(BitcoinOpCodeConst.CODE_OPS[byte]!);
        index = index + 1;
      } else if (!hasSegwit && byte == 0x4c) {
        int bytesToRead = scriptBytes[index + 1];
        index = index + 1;
        commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4d) {
        int bytesToRead = readUint16LE(scriptBytes, index + 1);

        index = index + 3;
        commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4e) {
        int bytesToRead = readUint32LE(scriptBytes, index + 1);

        index = index + 5;
        commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else {
        final viAndSize = IntUtils.decodeVarint(scriptBytes.sublist(index, index + 9));
        int dataSize = viAndSize.item1;
        int size = viAndSize.item2;
        final lastIndex = (index + size + dataSize) > scriptBytes.length
            ? scriptBytes.length
            : (index + size + dataSize);
        commands.add(BytesUtils.toHexString(scriptBytes.sublist(index + size, lastIndex)));
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  dynamic findScriptParam(int index) {
    if (index < script.length) {
      return script[index];
    }
    return null;
  }

  BitcoinAddressType? getAddressType() {
    if (script.isEmpty) return null;

    if (script.every((x) => x is int) &&
        script.length == 66 &&
        (script[0] == 2 || script[0] == 3) &&
        (script[33] == 2 || script[33] == 3)) {
      return SegwitAddresType.mweb;
    }

    final first = findScriptParam(0);
    final sec = findScriptParam(1);
    if (sec == null || sec is! String) {
      return null;
    }

    if (first == "OP_0") {
      final lockingScriptBytes = opPushData(sec);

      if (lockingScriptBytes.length == 21) {
        return SegwitAddresType.p2wpkh;
      } else if (lockingScriptBytes.length == 33) {
        return SegwitAddresType.p2wsh;
      }
    } else if (first == "OP_1") {
      final lockingScriptBytes = opPushData(sec);

      if (lockingScriptBytes.length == 33) {
        return SegwitAddresType.p2tr;
      }
    }

    final third = findScriptParam(2);
    final fourth = findScriptParam(3);
    final fifth = findScriptParam(4);
    if (first == "OP_DUP") {
      if (sec == "OP_HASH160" &&
          opPushData(third).length == 21 &&
          fourth == "OP_EQUALVERIFY" &&
          fifth == "OP_CHECKSIG") {
        return P2pkhAddressType.p2pkh;
      }
    } else if (first == "OP_HASH160" && opPushData(sec).length == 21 && third == "OP_EQUAL") {
      return P2shAddressType.p2pkhInP2sh;
    } else if (sec == "OP_CHECKSIG") {
      if (first.length == 66) {
        return PubKeyAddressType.p2pk;
      }
    }

    return null;
  }

  String toAddress() {
    final addressType = getAddressType();
    if (addressType == null) {
      throw ArgumentError("Invalid script");
    }

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case P2shAddressType.p2pkhInP2sh:
        return P2shAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddresType.p2wpkh:
        return P2wpkhAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddresType.p2wsh:
        return P2wshAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddresType.p2tr:
        return P2trAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
    }

    throw ArgumentError("Invalid script");
  }

  /// returns a serialized byte version of the script
  List<int> toBytes() {
    if (script.isEmpty) return <int>[];
    if (script.every((x) => x is int)) return script.cast();
    DynamicByteTracker scriptBytes = DynamicByteTracker();
    for (var token in script) {
      if (BitcoinOpCodeConst.OP_CODES.containsKey(token)) {
        scriptBytes.add(BitcoinOpCodeConst.OP_CODES[token]!);
      } else if (token is int && token >= 0 && token <= 16) {
        scriptBytes.add(BitcoinOpCodeConst.OP_CODES['OP_$token']!);
      } else {
        if (token is int) {
          scriptBytes.add(pushInteger(token));
        } else {
          scriptBytes.add(opPushData(token));
        }
      }
    }

    return scriptBytes.toBytes();
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }

  @override
  String toString() {
    return "Script{script: ${script.join(", ")}}";
  }
}
