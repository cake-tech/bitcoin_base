import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class Script {
  static final Script empty = Script();
  Script._({required List<dynamic> script})
      : script = script.immutable,
        _scriptBytes = _toBytes(script).asImmutableBytes;
  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(script: json["script"]);
  }
  factory Script({List<dynamic> script = const []}) {
    for (final i in script) {
      if (i is! String && i is! int && i is! BitcoinOpcode) {
        throw DartBitcoinPluginException(
            "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.");
      }
    }
    List<dynamic> scripts = [];
    for (final token in script) {
      if (token is BitcoinOpcode) {
        if (token.isOpPushData) continue;
        scripts.add(token.name);
        continue;
      }
      final opcode = BitcoinOpcode.findByName(token.toString());
      if (opcode != null) {
        scripts.add(opcode.name);
      } else if (token is int && token >= 0 && token <= 16) {
        scripts.add('OP_$token');
      } else {
        if (token is int) {
          final opcode = BitcoinOpcode.findByValue(token);
          if (opcode?.isOpPushData ?? false) continue;
          scripts.add(token);
        } else {
          final tokenBytes = BytesUtils.tryFromHexString(token);
          if (tokenBytes == null) {
            throw DartBitcoinPluginException(
                "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.");
          }
          scripts.add(StringUtils.strip0x((token as String).toLowerCase()));
        }
      }
    }

    return Script._(script: scripts);
  }
  final List<dynamic> script;
  final List<int> _scriptBytes;

  factory Script.deserialize({required List<int> bytes}) {
    final List<String> commands = [];
    int index = 0;
    while (index < bytes.length) {
      final byte = bytes[index];
      final opcode = BitcoinOpcode.findByValue(byte);
      if (opcode != null) {
        if (!opcode.isOpPushData) {
          commands.add(opcode.name);
        }

        /// skip op
        index = index + 1;
        if (opcode == BitcoinOpcode.opPushData1) {
          // get len
          final bytesToRead = bytes[index];
          // skip len
          index = index + 1;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));

          /// add length
          index = index + bytesToRead;
        } else if (opcode == BitcoinOpcode.opPushData2) {
          /// get len
          final bytesToRead = readUint16LE(bytes, index);
          index = index + 2;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        } else if (opcode == BitcoinOpcode.opPushData4) {
          final bytesToRead = readUint32LE(bytes, index);

          index = index + 4;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        }
      } else {
        final viAndSize = IntUtils.decodeVarint(bytes.sublist(index));
        final dataSize = viAndSize.item1;
        final size = viAndSize.item2;
        final lastIndex = (index + size + dataSize) > bytes.length
            ? bytes.length
            : (index + size + dataSize);
        commands.add(
            BytesUtils.toHexString(bytes.sublist(index + size, lastIndex)));
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  static List<int> _toBytes(List<dynamic> script) {
    if (script.isEmpty) return <int>[];
    final scriptBytes = DynamicByteTracker();
    for (final token in script) {
      final opcode = BitcoinOpcode.findByName(token.toString());
      if (opcode != null) {
        scriptBytes.add([opcode.value]);
      } else {
        if (token is int) {
          scriptBytes.add(BitcoinScriptUtils.pushInteger(token));
        } else {
          final tokenBytes = BytesUtils.tryFromHexString(token);
          if (tokenBytes == null) {
            throw DartBitcoinPluginException(
                "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.");
          }
          scriptBytes.add(BitcoinScriptUtils.opPushData(tokenBytes));
        }
      }
    }

    return scriptBytes.toBytes();
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

  List<int> toBytes() {
    return _scriptBytes.clone();
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }

  Map<String, dynamic> toJson() {
    return {"script": script};
  }

  @override
  String toString() {
    return script.toString();
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is Script) {
      return BytesUtils.bytesEqual(_scriptBytes, other._scriptBytes);
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(_scriptBytes);
}
