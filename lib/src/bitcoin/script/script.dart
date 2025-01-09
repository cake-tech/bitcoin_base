import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/models/network.dart';
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
            'A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.'),
        script = List.unmodifiable(script);
  final List<dynamic> script;

  static Script deserialize({
    List<int>? bytes,
    String? hexData,
    bool hasSegwit = false,
  }) {
    return fromRaw(bytes: bytes, hexData: hexData, hasSegwit: hasSegwit);
  }

  static Script fromRaw({
    List<int>? bytes,
    String? hexData,
    bool hasSegwit = false,
  }) {
    final commands = <String>[];
    var index = 0;
    final scriptBytes = bytes ?? (hexData != null ? BytesUtils.fromHexString(hexData) : null);
    if (scriptBytes == null) {
      throw DartBitcoinPluginException("Invalid script");
    }
    while (index < scriptBytes.length) {
      final byte = scriptBytes[index];
      if (BitcoinOpCodeConst.CODE_OPS.containsKey(byte)) {
        if (!BitcoinOpCodeConst.isOpPushData(byte)) {
          commands.add(BitcoinOpCodeConst.CODE_OPS[byte]!);
        }

        /// skip op
        index = index + 1;
        if (byte == BitcoinOpCodeConst.opPushData1) {
          // get len
          final bytesToRead = scriptBytes[index];
          // skip len
          index = index + 1;
          commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));

          /// add length
          index = index + bytesToRead;
        } else if (byte == BitcoinOpCodeConst.opPushData2) {
          /// get len
          final bytesToRead = readUint16LE(scriptBytes, index);
          index = index + 2;
          commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        } else if (byte == BitcoinOpCodeConst.opPushData4) {
          final bytesToRead = readUint32LE(scriptBytes, index);

          index = index + 4;
          commands.add(BytesUtils.toHexString(scriptBytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        }
      } else {
        final viAndSize = IntUtils.decodeVarint(scriptBytes.sublist(index));
        final dataSize = viAndSize.item1;
        final size = viAndSize.item2;
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
      return SegwitAddressType.mweb;
    }

    final first = findScriptParam(0);
    final sec = findScriptParam(1);
    if (sec == null || sec is! String) {
      return null;
    }

    if (first == "OP_0") {
      final lockingScriptBytes = opPushData(sec);

      if (lockingScriptBytes.length == 21) {
        return SegwitAddressType.p2wpkh;
      } else if (lockingScriptBytes.length == 33) {
        return SegwitAddressType.p2wsh;
      }
    } else if (first == "OP_1") {
      final lockingScriptBytes = opPushData(sec);

      if (lockingScriptBytes.length == 33) {
        return SegwitAddressType.p2tr;
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
      throw DartBitcoinPluginException("Invalid script");
    }

    switch (addressType) {
      case P2pkhAddressType.p2pkh:
        return P2pkhAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case P2shAddressType.p2pkhInP2sh:
        return P2shAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddressType.p2wpkh:
        return P2wpkhAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddressType.p2wsh:
        return P2wshAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
      case SegwitAddressType.p2tr:
        return P2trAddress.fromScriptPubkey(script: this).toAddress(BitcoinNetwork.mainnet);
    }

    throw DartBitcoinPluginException("Invalid script");
  }

  /// returns a serialized byte version of the script
  List<int> toBytes() {
    if (script.isEmpty) return <int>[];
    final scriptBytes = DynamicByteTracker();
    for (final token in script) {
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
